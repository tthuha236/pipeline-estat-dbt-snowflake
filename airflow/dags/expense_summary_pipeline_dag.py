from utils.load_config_info import load_config
from airflow import DAG
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from datetime import datetime

dag_id = "expense_summary_pipeline_dag"
config = load_config(dag_id)
models = config["dbt"]["models"]
aws_conn_id = config["aws"]["aws_conn_id"]
region_name = config["aws"]["region_name"]

with DAG(
    dag_id=dag_id,
    start_date=datetime.utcnow(),
    schedule=None,
    catchup=False
) as dag:
    run_dbt = EcsRunTaskOperator(
        task_id = "run_dbt_model",
        cluster = config["aws"]["ecs"]["cluster"],
        aws_conn_id = aws_conn_id,
        task_definition = config["aws"]["ecs"]["task"],
        launch_type="FARGATE",
        overrides = {
            "containerOverrides": [{
                "name": config["dbt"]["image"],
                "command": ["dbt","run", "--select", *models]
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