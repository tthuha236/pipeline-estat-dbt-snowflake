from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeSqlApiOperator
from airflow.exceptions import AirflowFailException
from configs.aws import AWS_CONN_ID, S3_BUCKET, RAW_FOLDER, STAGING_FOLDER, REGION_NAME
from configs.estat import BASE_URL
from configs.snowflake import SNOWFLAKE_CONN_ID, S3_STAGE_NAME, ESTAT_DATABASE, ESTAT_SCHEMA_STG, DEFAULT_WAREHOUSE, SNOWFLAKE_SQL_DIR
from configs.airflow import AIRFLOW_ROOT_DIR
from datetime import datetime
import json

# aws lambda function name
LAMBDA_CRAWL_DATA = "estat_crawl_newest_expense_data"
LAMBDA_CLEAN_DATA = "estat_clean_expense_data"
TARGET_FOLDER = "expense"

# snowflake file info
SQL_LOAD_DATA_FILE_PATH = f"{AIRFLOW_ROOT_DIR}/{SNOWFLAKE_SQL_DIR}/{TARGET_FOLDER}/load_expense.sql"
TARGET_TABLE = "fact_expense_stg"

# data source info
STAT_URL = "https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200561&tstat=000000330001&cycle=1&tclass1=000000330001&tclass2=000000330004&tclass3=000000330005&tclass4val=0"

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
        if function_name == LAMBDA_CRAWL_DATA: return "invoke_clean_lambda"
    if response_status == 404:
        return "skip_task"
    if response_status in [400,500]:
        raise AirflowFailException(f"Lambda function failed. {payload_data}")

def skip_task():
    print("Skip task to invoke clean lambda function because no file is downloaded")

def dummy_task(**context):
    context["ti"].xcom_push(key="output_file", value="stg/expense/expense_202403_20250801.csv")

with DAG(
    dag_id = "fact_expense_pipeline_dag",
    start_date = datetime(2025,7,28),
    schedule = None,
    catchup = False
) as dag:
# read sql file to load data from s3 bucket to stg table in snowflake
    with open(SQL_LOAD_DATA_FILE_PATH) as f:
        copy_sql = f.read()

    # invoke_crawl_lambda = LambdaInvokeFunctionOperator(
    #     task_id = "invoke_crawl_lambda",
    #     function_name = LAMBDA_CRAWL_DATA, 
    #     aws_conn_id = AWS_CONN_ID,
    #     payload = json.dumps({
    #         "target_bucket": S3_BUCKET,
    #         "target_folder": RAW_FOLDER + "/" + TARGET_FOLDER,
    #         "downloaded_list": f"{RAW_FOLDER}/{TARGET_FOLDER}/downloaded_list",
    #         "base_url": BASE_URL,
    #         "stat_url": STAT_URL
    #     }),
    #     region_name = REGION_NAME,
    #     invocation_type = "RequestResponse",
    #     )

    # check_crawl_lambda_response = BranchPythonOperator(
    #     task_id = "check_crawl_lambda_response",
    #     python_callable = check_lambda_response,
    # )

    # invoke_clean_lambda = LambdaInvokeFunctionOperator(
    #     task_id = "invoke_clean_lambda",
    #     function_name = LAMBDA_CLEAN_DATA,
    #     aws_conn_id = AWS_CONN_ID,
    #     payload = json.dumps({
    #         "s3_bucket": S3_BUCKET,
    #         "raw_folder": RAW_FOLDER + "/" + TARGET_FOLDER,
    #         "clean_folder": STAGING_FOLDER + "/" + TARGET_FOLDER,
    #         "file_name": "{{ ti.xcom_pull(key='output_file', task_ids='check_crawl_lambda_response')}}",
    #     }),
    #     region_name = REGION_NAME
    # )

    # check_clean_lambda_response = PythonOperator(
    #     task_id = "check_clean_lambda_response",
    #     python_callable = check_lambda_response
    # )

    # skip_task = PythonOperator(
    #     task_id = "skip_task",
    #     python_callable = skip_task
    # )

    # load_data_to_stg_table = SnowflakeSqlApiOperator(
    #     task_id = "load_data_to_stg_table",
    #     snowflake_conn_id = SNOWFLAKE_CONN_ID,
    #     sql = copy_sql.replace("{output_file}", "{{ ti.xcom_pull(key='output_file',task_ids='dummy_task')}}"),
    #     warehouse = DEFAULT_WAREHOUSE,
    #     params = {
    #         "db": ESTAT_DATABASE,
    #         "stg_schema": ESTAT_SCHEMA_STG,
    #         "stg_table": TARGET_TABLE,
    #         "s3_stage": S3_STAGE_NAME,
    #     }
    # )

    dummy_task = PythonOperator(
        task_id = "dummy_task",
        python_callable = dummy_task
    )

    # invoke_crawl_lambda >> check_crawl_lambda_response >> [invoke_clean_lambda, skip_task] 
    # invoke_clean_lambda >> check_clean_lambda_response >> load_data_to_stg_table
    # dummy_task >> load_data_to_stg_table
