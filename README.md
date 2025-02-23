# etl-bi

## Setup

1. Generate Fernet key and add it to .env file:
```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Edit dbt profile:
```bash
vim ~/.dbt/profiles.yml 
```


## References

- https://github.com/justinbchau/custom-elt-project