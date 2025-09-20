from airflow import DAG
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from utils.load_config_info import load_config
from datetime import datetime
import os

# # data source info
# STAT_URL = "https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200561&tstat=000000330001&cycle=1&tclass1=000000330001&tclass2=000000330004&tclass3=000000330005&tclass4val=0"
dag_id = "dim_location_pipeline_dag"
env = os.getenv("ENVIRONMENT", "")
print(f"Running in ${env} environment")
config = load_config(dag_id)

# aws info
aws_conn_id = config["aws"]["aws_conn_id"]
region_name = config["aws"]["region_name"]

with DAG(
    dag_id = dag_id,
    start_date = datetime(2025,7,28),
    schedule = None,
    catchup = False
) as dag:
# read sql file to load data from s3 bucket to stg table in snowflake
    run_dbt = EcsRunTaskOperator(
        task_id = "run_dbt_seed",
        cluster = config["aws"]["ecs"]["cluster"],
        aws_conn_id = aws_conn_id,
        task_definition = config["aws"]["ecs"]["task"],
        launch_type="FARGATE",
        overrides = {
            "containerOverrides": [{
                "name": config["dbt"]["image"],
                "command": ["dbt","build","--select","dim_city_stg","dim_city_region_stg","dim_location"]
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

    run_dbt
