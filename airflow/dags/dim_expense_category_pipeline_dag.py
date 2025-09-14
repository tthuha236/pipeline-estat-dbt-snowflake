from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeSqlApiOperator
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.exceptions import AirflowFailException
from utils.load_config_info import load_config
from docker.types import Mount
from datetime import datetime
import json
import os

# # data source info
# STAT_URL = "https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200561&tstat=000000330001&cycle=1&tclass1=000000330001&tclass2=000000330004&tclass3=000000330005&tclass4val=0"
dag_id = "dim_expense_category_pipeline_dag"
env = os.getenv("ENVIRONMENT", "")
print(f"Running in ${env} environment")
config = load_config(dag_id)

# aws info
aws_conn_id = config["aws"]["aws_conn_id"]
region_name = config["aws"]["region_name"]
s3_bucket = config["aws"]["s3"]["bucket"]
raw_folder = config["aws"]["s3"]["raw_folder"]
staging_folder  = config["aws"]["s3"]["staging_folder"]
target_folder = config["aws"]["s3"]["target_folder"]
lambda_crawl_data = config["aws"]["lambda"]["crawl_data"].replace("{{ env }}", env)
lambda_clean_data = config["aws"]["lambda"]["clean_data"].replace("{{ env }}", env)

# snowflake sql file path to load data from s3 to table
sql_load_data_file_path = f'{config["airflow"]["airflow_root_dir"]}/{config["snowflake"]["sql_dir"]}/{config["snowflake"]["sql"]["load_data_file"]}'


def check_lambda_response(**context):
    """
        Check the response of the lambda function to crawl data/clean data
    """
    task = context['task']
    upstream_task_id = list(task.upstream_task_ids)[0]
    response = context["ti"].xcom_pull(task_ids=upstream_task_id, key="return_value")
    
    # if payload is bytesIO, decode
    if hasattr(response, "read"):
        payload = response.read().decode('utf-8')
    else:
        payload = str(response)

    # parse json
    try:
        payload_data = json.loads(payload)
    except:
        payload_data = {}
    
    response_status = payload_data.get("status")
    function_name = payload_data.get("function_name")

    if response_status == 200:
        output_file = payload_data.get("output_file")
        context["ti"].xcom_push(key="output_file", value=output_file)
        if function_name == lambda_crawl_data: return "invoke_clean_lambda"
    if response_status == 404:
        return "skip_task"
    if response_status in [400,500]:
        raise AirflowFailException(f"Lambda function failed. {payload_data}")

def skip_task():
    print("Skip task to invoke clean lambda function because no file is downloaded")

with DAG(
    dag_id = dag_id,
    start_date = datetime(2025,7,28),
    schedule = None,
    catchup = False
) as dag:
# read sql file to load data from s3 bucket to stg table in snowflake
    with open(sql_load_data_file_path) as f:
        copy_sql = f.read()

    invoke_crawl_lambda = LambdaInvokeFunctionOperator(
        task_id = "invoke_crawl_lambda",
        function_name = lambda_crawl_data, 
        aws_conn_id = aws_conn_id,
        payload = json.dumps({
            "target_bucket": s3_bucket,
            "target_folder": raw_folder + "/" + target_folder,
            "href": config["data_source"]["href"]
        }),
        region_name = region_name,
        invocation_type = "RequestResponse",
        )
        

    check_crawl_lambda_response = BranchPythonOperator(
        task_id = "check_crawl_lambda_response",
        python_callable = check_lambda_response,
    )

    invoke_clean_lambda = LambdaInvokeFunctionOperator(
        task_id = "invoke_clean_lambda",
        function_name = lambda_clean_data,
        aws_conn_id = aws_conn_id,
        payload = json.dumps({
            "s3_bucket": s3_bucket,
            "raw_folder": raw_folder + "/" + target_folder,
            "clean_folder": staging_folder + "/" + target_folder,
            "file_name": "{{ ti.xcom_pull(key='output_file', task_ids='check_crawl_lambda_response')}}",
        }),
        region_name = region_name
    )

    check_clean_lambda_response = PythonOperator(
        task_id = "check_clean_lambda_response",
        python_callable = check_lambda_response
    )

    skip_task = PythonOperator(
        task_id = "skip_task",
        python_callable = skip_task
    )

    load_data_to_stg_table = SnowflakeSqlApiOperator(
        task_id = "load_data_to_stg_table",
        snowflake_conn_id = config["snowflake"]["snowflake_conn_id"],
        sql = copy_sql.replace("{output_file}", "{{ ti.xcom_pull(key='output_file',task_ids='check_clean_lambda_response')}}"),
        warehouse = config["snowflake"]["default_warehouse"],
        params = {
            "db": config["snowflake"]["estat_database"],
            "stg_schema": config["snowflake"]["estat_schema_stg"],
            "stg_table": config["snowflake"]["sql"]["target_table"],
            "s3_stage": config["snowflake"]["s3_stage_name"],
        }
    )

    run_dbt = EcsRunTaskOperator(
        task_id = "run_dbt_model",
        cluster = config["aws"]["ecs"]["cluster"],
        aws_conn_id = aws_conn_id,
        task_definition = config["aws"]["ecs"]["task"],
        launch_type="FARGATE",
        overrides = {
            "containerOverrides": [{
                "name": config["dbt"]["image"],
                "command": ["dbt","run", "--select", config["dbt"]["model"]]
            }]
        },
        network_configuration= {
             "awsvpcConfiguration": {
             "subnets": config["aws"]["ecs"]["subnets"],
             "securityGroups": config["aws"]["ecs"]["securityGroups"],
             "assignPublicIp": "ENABLED",
            }
        },
        region_name = region_name
    )

    invoke_crawl_lambda >> check_crawl_lambda_response >> [invoke_clean_lambda, skip_task] 
    invoke_clean_lambda >> check_clean_lambda_response >> load_data_to_stg_table >> run_dbt
