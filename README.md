# etl-bi

## Prerequisites

1. Generate Fernet key and add it to .env file:
```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

2. Append the following to your dbt profile `~/.dbt/profiles.yml`:
```yml
etl:
  outputs:
    dev:
      dbname: destination_db
      host: host.docker.internal
      pass: postgres
      port: 5434
      schema: public
      threads: 1
      type: postgres
      user: postgres
  target: dev
```

3. In file [etl_dag.py](airflow/dags/etl_dag.py) change DBT_PROJECT_SOURCE_PATH and DBT_PROFILE_SOURCE_PATH to your local paths.
```python
DBT_PROJECT_SOURCE_PATH = "/Users/dimaaspisov/Desktop/GitHub/etl-bi/dbt/etl"
DBT_PROFILE_SOURCE_PATH = "/Users/dimaaspisov/.dbt"
```

4. Make sure that ports 5433 and 5434 are free.

## Run

1. Build and start containers:
```bash 
docker compose up -d
```

2. Login to Airflow at http://localhost:8080/ with credentials `airflow`/`airflow` and run `etl_and_dbt` DAG.

3. Transformed data will appear in `destination_db` database with schema `presentation` in tables:
    - `frequent_flyers`
    - `airport_traffic`

4. Generate a superset secret key and add it to `.env` file:
```bash
python -c "import os; print(os.urandom(24).hex())"
```

5. Connect to Superset at http://localhost:8088/ with credentials `admin`/`admin` and create a new dashboard.


## References

- https://github.com/justinbchau/custom-elt-project