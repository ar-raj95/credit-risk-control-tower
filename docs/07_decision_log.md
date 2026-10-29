# Decision log

Short records of design decisions, so a reviewer can see what was chosen and why.

| ID | Decision | Alternatives considered | Reason |
|---|---|---|---|
| DEC-01 | DuckDB as the warehouse | Snowflake trial, BigQuery sandbox | Free and local: anyone can clone and run in about 5 minutes; no trial expiry breaking the repo |
| DEC-02 | Business logic in dbt; DAX only aggregates | Logic in Power Query or DAX | Testable, reviewable, one definition shared by every consumer |
| DEC-03 | Raw data landed as text | Typed load in Python | Failed casts become nulls that DQ rules can count, instead of rows silently dropped at load |
| DEC-04 | DQ rules run on staging, before cleaning | Run on the cleaned mart | Measures what the source sent; cleaning would hide defects |
| DEC-05 | Two-layer DQ: gates and scorecard | Tests only, or scorecard only | Tests give pass or fail but no trend; the scorecard gives trend but can't stop a bad refresh |
| DEC-06 | All-or-nothing Parquet export | Export each successful model | A partial export would mix fresh and stale tables in the report |
| DEC-07 | PSI as a SQL macro with fixed baseline deciles | Python model | Stays in the tested SQL pipeline; one line per new feature |
| DEC-08 | Thresholds, mappings and rules as seed files | Hard-coded in SQL or DAX | Business-owned values change by reviewed pull request |
| DEC-09 | Synthetic fixture for CI | Commit a sample of real data | Avoids redistributing source data; planted defects prove each rule |
| DEC-10 | dbt Core 1.x, not v2 | dbt v2 | 1.x tested end to end here; v2 upgrade planned once syntax is verified |
