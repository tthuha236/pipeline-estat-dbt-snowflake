from airflow.dags.utils.load_config_info import load_config
from airflow import DAG
from airflow.operators.dummy import DummyOperator
from datetime import datetime

dag_id = "expense_summary_pipeline_dag"
config = load_config(dag_id)

with DAG(
    dag_id=dag_id,
    start_date=datetime(2025,9,15),
    schedule=None,
    catchup=False
) as dag:
    dummy_task = DummyOperator(task_id="dummy_task")
    dummy_task