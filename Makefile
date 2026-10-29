# Shortcuts. Run from the repo root.
.PHONY: fixture real build docs lint clean

fixture:          ## Synthetic data, no download needed
	python ingest/make_fixture.py --out data/fixture.csv
	python ingest/load_raw.py --input data/fixture.csv

real:             ## Full Kaggle file in data/
	python ingest/load_raw.py --input data/accepted_2007_to_2018Q4.csv.gz

build:
	cd dbt && dbt build

docs:
	cd dbt && dbt docs generate && dbt docs serve

lint:
	DUCKDB_PATH=$(PWD)/data/warehouse.duckdb sqlfluff lint dbt/models dbt/tests

clean:
	rm -rf dbt/target dbt/logs data/warehouse.duckdb data/marts/*.parquet
