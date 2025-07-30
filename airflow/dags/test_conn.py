from airflow import DAG
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
from datetime import datetime
import json
from airflow.providers.amazon.aws.hooks.base_aws import AwsBaseHook

# # Replace 'aws_default' with your actual connection ID
# aws_hook = AwsBaseHook(aws_conn_id='estat-airflow-aws-connection')

# try:
#     aws_hook.test_connection()
#     print("AWS connection successful!")
# except Exception as e:
#     print(f"AWS connection failed: {e}")   

with DAG(
    dag_id = "test_conn_dag",
    start_date = datetime(2025,7,28),
    schedule = None,
    catchup = False
) as dag:
    invoke_lambda = LambdaInvokeFunctionOperator(
        task_id = "invoke_lambda",
        function_name = "estat_test_conn", 
        aws_conn_id = "estat-airflow-aws-connection",
        payload = json.dumps({"test": "testtest"}),
        region_name = "ap-northeast-1"
    )
    invoke_lambda