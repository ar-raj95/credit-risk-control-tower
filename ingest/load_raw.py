"""
Land the LendingClub file in DuckDB as raw text, exactly as received.

Everything is loaded as VARCHAR on purpose: typing, cleaning and validation
happen in dbt, where they are tested and documented. The raw layer stays
untouched so data-quality issues can be measured, not hidden.

Usage:
    python ingest/load_raw.py --input data/accepted_2007_to_2018Q4.csv.gz
    python ingest/load_raw.py --input data/fixture.csv          # CI fixture
"""
import argparse
from pathlib import Path

import duckdb

RAW_COLUMNS = [
    "id", "loan_amnt", "term", "int_rate", "installment", "grade", "sub_grade",
    "emp_length", "home_ownership", "annual_inc", "verification_status", "issue_d",
    "loan_status", "purpose", "addr_state", "dti", "delinq_2yrs", "fico_range_low",
    "fico_range_high", "revol_util", "open_acc", "total_pymnt", "total_rec_prncp",
    "recoveries",
]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="Kaggle CSV or .csv.gz, or the CI fixture")
    ap.add_argument("--db", default="data/warehouse.duckdb")
    a = ap.parse_args()

    src = Path(a.input)
    if not src.exists():
        raise SystemExit(f"Input not found: {src}")
    Path(a.db).parent.mkdir(parents=True, exist_ok=True)
    (Path(a.db).parent / "marts").mkdir(exist_ok=True)      # dbt exports Parquet here

    cols = ", ".join(f'"{c}"' for c in RAW_COLUMNS)
    con = duckdb.connect(a.db)
    con.execute("create schema if not exists raw")
    con.execute(
        f"""
        create or replace table raw.lendingclub_loans as
        select {cols}, current_timestamp as _loaded_at, ? as _source_file
        from read_csv(?, header = true, all_varchar = true, ignore_errors = true)
        """,
        [src.name, str(src)],
    )
    n = con.execute("select count(*) from raw.lendingclub_loans").fetchone()[0]
    con.close()
    print(f"Loaded {n:,} raw rows from {src.name} into {a.db} (raw.lendingclub_loans)")


if __name__ == "__main__":
    main()
