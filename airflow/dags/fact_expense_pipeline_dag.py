from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from airflow.exceptions import AirflowFailException
from datetime import datetime
import json

def check_lambda_response(**context):
    response = context["ti"].xcom_pull(task_ids = "invoke_lambda", key="return_value")
    print(response)

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

    if payload_data.get('status') in [400,500]:
        raise AirflowFailException(f"Lambda function failed. {payload_data}")

with DAG(
    dag_id = "fact_expense_pipeline_dag",
    start_date = datetime(2025,7,28),
    schedule = None,
    catchup = False
) as dag:
    invoke_lambda = LambdaInvokeFunctionOperator(
        task_id = "invoke_lambda",
        function_name = "estat_crawl_newest_expense_data", 
        aws_conn_id = "estat-airflow-aws-connection",
        payload = json.dumps({
            "target_bucket": "estat-dbt-sf",
            "target_folder": "raw",
            "downloaded_list": "raw/downloaded_list",
            "base_url": "https://www.e-stat.go.jp",
            "stat_url": "https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200561&tstat=000000330001&cycle=1&tclass1=000000330001&tclass2=000000330004&tclass3=000000330005&tclass4val=0"
        }),
        region_name = "ap-northeast-1",
        invocation_type = "RequestResponse",
        )
    check_response = PythonOperator(
        task_id = "check_lambda_response",
        python_callable = check_lambda_response,
    )
    
    invoke_lambda >> check_response
