# Data quality rulebook

**Source of truth:** `dbt/seeds/dq_rule_catalog.csv` (scorecard rules) and the dbt test YAML files (gates). This page explains them; if the two disagree, the code wins and this page is updated.

## How data quality works in this product

There are two layers, and they do different jobs:

| Layer | Purpose | Effect on refresh | Where |
|---|---|---|---|
| **Gates** (dbt tests) | Stop data that would make KRIs wrong | **Block**: build fails, downstream skipped, no export. **Warn**: logged, export continues | `_stg.yml`, `_int.yml`, `_core.yml`, `_seeds.yml` |
| **Scorecard** (`fct_dq_results`) | Measure defects over time so they get fixed at source | None. Reported on Page 6 | `dq_rule_catalog.csv` |

Scorecard rules run on **staging**, before deduplication and cleaning, so the scorecard shows what the source actually sent.

## Gates

| Check | Column | Gate | Why it blocks or warns |
|---|---|---|---|
| Status is mapped | `stg.loan_status` | Block | An unmapped status would be counted as neither default nor performing, changing every rate |
| Loan id not null | `stg.loan_id` | Block | Loans without an id can't be deduplicated or traced |
| Issue date not null | `stg.issue_date` | Block | Loans without a date fall out of every vintage |
| Grade is A to G | `stg.grade` | Block | A new grade would be missing from the grade dimension |
| Loan id unique after dedup | `int.loan_id`, `fct_loans.loan_id` | Block | Duplicates double-count exposure |
| Flags consistent | `fct_loans` | Block | A loan can't be both closed and active, or default without being closed |
| Contract on `fct_loans` | All columns | Block | A changed type or column would break the report silently |
| Totals reconcile to source | `fct_loans` vs staging | Block | Over 0.1% difference means loans were lost or duplicated |
| DTI within 0 to 100 | `stg.dti` | Warn | Affects DTI bands only; also tracked as DQ06 |

## Scorecard rules

| Rule | Dimension | Field | Severity | Fails when | Owner |
|---|---|---|---|---|---|
| DQ01 | Completeness | annual_income | High | Income missing | Origination data owner |
| DQ02 | Completeness | dti | High | DTI missing | Origination data owner |
| DQ03 | Completeness | emp_length | Medium | Employment length missing | Origination data owner |
| DQ04 | Completeness | revol_util | Medium | Revolving utilization missing | Bureau data owner |
| DQ05 | Validity | annual_income | High | Income zero or negative | Origination data owner |
| DQ06 | Validity | dti | High | DTI below 0 or above 100 | Origination data owner |
| DQ07 | Validity | fico_range_low | High | FICO outside 300 to 850 | Bureau data owner |
| DQ08 | Validity | interest_rate_pct | Medium | Rate outside 0 to 40% | Pricing data owner |
| DQ09 | Validity | revol_util | Low | Utilization above 150% | Bureau data owner |
| DQ10 | Uniqueness | loan_id | High | Id appears more than once | Platform data engineering |
| DQ11 | Consistency | fico_range | Medium | FICO high below FICO low | Bureau data owner |
| DQ12 | Validity | state_code | Medium | Not a valid US state or DC | Origination data owner |

## Severity and response

Thresholds come from the `dq_pass_rate` row in `risk_appetite.csv` (illustrative: Amber below 98%, Red below 95%).

| Severity | Meaning | Response if Amber or Red |
|---|---|---|
| High | Directly changes a KRI or segment | Owner investigates within 5 working days; consider promoting to a gate |
| Medium | Affects a band, drill-down or secondary metric | Owner investigates within the next monthly cycle |
| Low | Cosmetic or rare | Logged; reviewed quarterly |

## Adding or changing a rule

1. Add a row to `dq_rule_catalog.csv` with ID, dimension, field, severity, description, SQL fail condition and owner.
2. Open a pull request. CI builds the pipeline and the new rule appears in `fct_dq_results`.
3. If the rule should block the refresh, also add a dbt test with severity error, and update the Gates table here.
