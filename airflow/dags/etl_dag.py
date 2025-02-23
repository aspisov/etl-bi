from datetime import datetime, timedelta
from airflow import DAG
from docker.types import Mount
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.docker.operators.docker import DockerOperator
import subprocess

DBT_PROJECT_SOURCE_PATH = "/Users/dimaaspisov/Desktop/GitHub/etl-bi/dbt/etl"
DBT_PROFILE_SOURCE_PATH = "/Users/dimaaspisov/.dbt"  # don't use ~/.dbt/

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
}


def run_etl_script():
    script_path = "/opt/airflow/etl/etl_script.py"
    result = subprocess.run(
        ["python", script_path], capture_output=True, text=True
    )
    if result.returncode != 0:
        raise Exception(f"ETL script failed with error: {result.stderr}")
    else:
        print("ETL script executed successfully")


def create_dag():
    dag = DAG(
        "etl_and_dbt",
        default_args=default_args,
        description="ETL and DBT DAG",
        schedule_interval=timedelta(days=1),
        start_date=datetime(2025, 2, 23),
        catchup=False,
    )

    t1 = PythonOperator(
        task_id="run_etl_script",
        python_callable=run_etl_script,
        dag=dag,
    )

    t2 = DockerOperator(
        task_id="run_dbt_transform",
        image="ghcr.io/dbt-labs/dbt-postgres:1.4.7",
        command=[
            "run",
            "--project-dir",
            "/root",
            "--project-dir",
            "/dbt",
            "--full-refresh",
        ],
        mount_tmp_dir=False,
        auto_remove="success",
        docker_url="unix://var/run/docker.sock",
        network_mode="bridge",
        mounts=[
            Mount(
                source=DBT_PROJECT_SOURCE_PATH,
                target="/dbt",
                type="bind",
            ),
            Mount(
                source=DBT_PROFILE_SOURCE_PATH,
                target="/root/.dbt",
                type="bind",
            ),
        ],
        dag=dag,
    )

    t1 >> t2
    return dag


dag = create_dag()
