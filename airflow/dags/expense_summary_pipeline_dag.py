from utils.load_config_info import load_config
from airflow import DAG
from airflow.providers.standard.operators.empty import EmptyOperator
from datetime import datetime

dag_id = "expense_summary_pipeline_dag"
config = load_config(dag_id)

with DAG(
    dag_id=dag_id,
    start_date=datetime.utcnow(),
    schedule=None,
    catchup=False
) as dag:
    dummy_task = EmptyOperator(task_id="dummy_task")
    dummy_task