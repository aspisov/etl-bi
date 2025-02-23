import subprocess
import time

SOURCE_CONFIG = {
    "host": "source_postgres",
    "port": "5432",
    "user": "postgres",
    "password": "postgres",
    "database": "source_db",
}

DESTINATION_CONFIG = {
    "host": "destination_postgres",
    "port": "5432",
    "user": "postgres",
    "password": "postgres",
    "database": "destination_db",
}


def wait_for_db(host, max_retries=5, delay=10):
    retries = 0
    while retries < max_retries:
        try:
            result = subprocess.run(
                ["pg_isready", "-h", host],
                check=True,
                capture_output=True,
                text=True,
            )
            if "accepting connections" in result.stdout:
                print(f"Database at {host} is ready")
                return True
            print(f"Waiting for database at {host} to be ready...")
            retries += 1
            time.sleep(delay)
        except subprocess.CalledProcessError as e:
            print(f"Error checking database at {host}: {e}")
            retries += 1
            time.sleep(delay)
    print(
        f"Failed to connect to database at {host} after {max_retries} retries"
    )
    return False


def main():
    if not wait_for_db(SOURCE_CONFIG["host"]):
        print("Source database is not ready. Exiting.")
        exit(1)

    if not wait_for_db(DESTINATION_CONFIG["host"]):
        print("Destination database is not ready. Exiting.")
        exit(1)

    dump_command = [
        "pg_dump",
        "-h",
        SOURCE_CONFIG["host"],
        "-p",
        SOURCE_CONFIG["port"],
        "-U",
        SOURCE_CONFIG["user"],
        "-d",
        SOURCE_CONFIG["database"],
        "-f",
        "data_dump.sql",
        "-w",
    ]

    subprocess_env = dict(
        PGPASSWORD=SOURCE_CONFIG["password"], PGPORT=SOURCE_CONFIG["port"]
    )

    print("Dumping data from source database...")
    subprocess.run(dump_command, check=True, env=subprocess_env)
    print("Data dumped successfully.")

    load_command = [
        "psql",
        "-h",
        DESTINATION_CONFIG["host"],
        "-p",
        DESTINATION_CONFIG["port"],
        "-U",
        DESTINATION_CONFIG["user"],
        "-d",
        DESTINATION_CONFIG["database"],
        "-a",
        "-f",
        "data_dump.sql",
    ]

    subprocess_env = dict(
        PGPASSWORD=DESTINATION_CONFIG["password"],
        PGPORT=DESTINATION_CONFIG["port"],
    )

    print("Restoring data to destination database...")
    subprocess.run(load_command, check=True, env=subprocess_env)
    print("Data restored successfully.")


if __name__ == "__main__":
    main()
