from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

# test change 5
def print_hello():
    print("Hello from task 1")

def print_world():
    print("Hello from task 2")

def combine():
    print("Hello world from task3")

with DAG(
    dag_id = "simple_python_task",
    start_date = datetime(2025,7,27),
    schedule = None,
    catchup = False,
    tags = ["simple", "python"]
) as dag:
    task1 = PythonOperator(
        task_id = "say_hello",
        python_callable = print_hello
    )

    task2 = PythonOperator(
        task_id  = "say_world",
        python_callable = print_world
    )

    task3 = PythonOperator(
        task_id = "combine_msg",
        python_callable = combine
    )

    [task1, task2] >> task3