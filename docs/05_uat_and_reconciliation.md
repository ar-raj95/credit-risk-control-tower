# UAT and reconciliation

Automated cases run on every build. Manual cases are run in Power BI Desktop at each release. Record the date and data used for each run.

**Last automated run:** 2026-10-29, full Kaggle file (2,260,701 raw rows). PASS=77, WARN=1 (DTI out of range, see I2 in the RAID log), ERROR=0.

## Automated

| ID | Story | Case | Expected | How |
|---|---|---|---|---|
| AUT-01 | US-02 | Mart loan count and funded amount vs staging | Difference 0.1% or less | `assert_fct_loans_reconciles_to_source` |
| AUT-02 | US-02 | Portfolio default rate from KRI table vs loan fact | Difference 0.0001 or less | `assert_kri_matches_loan_fact` |
| AUT-03 | US-07 | Unmapped loan status in source | Build fails; downstream skipped; no export | Relationships test; verified by injecting "Restructured" |
| AUT-04 | US-08 | Status flags, loss, bands and maturity on hand-built loans | All expected values match | Unit test `status_flags_loss_and_bands` |
| AUT-05 | US-09 | Column type change in `fct_loans` | Build fails with contract error | Enforced contract (seen during build when a key type drifted) |
| AUT-06 | US-04 | Planted defects in fixture | Each defect counted by its rule (for example DQ06 = 15, DQ11 = 10) | `fct_dq_results` on fixture |
| AUT-07 | US-03 | PSI values | Not null, 0 or above, valid status | Tests on `fct_psi` |

## Manual (Power BI)

| ID | Story | Steps | Expected | Result | Date |
|---|---|---|---|---|---|
| UAT-01 | US-01 | Open Page 1 | Each KRI card shows value and RAG colour | | |
| UAT-02 | US-01 | Change default_rate amber to 0.05 in the seed, run `dbt build`, refresh | Default rate card turns Amber or Red; no DAX edited | | |
| UAT-03 | US-02 | Select grade C and 2016 on Page 2 | All visuals filter; totals match the pandas or SQL check below | | |
| UAT-04 | US-02 | Open hidden reconciliation page | Difference column is 0 for every quarter | | |
| UAT-05 | US-07 | Run a failing build, then refresh Power BI | Report shows the previous data; no partial update | | |
| UAT-06 | US-10 | Open Page 3 | Immature quarters shaded with a note | | |
| UAT-07 | US-03 | Drill through from a Red PSI cell | Bin view shows baseline vs current share by decile | | |
| UAT-08 | US-04 | Open Page 6 | Each rule shows ID, severity, owner, trend and failing count | | |
| UAT-09 | US-05 | Hover each KPI; click "?" | Tooltip definition; navigates to Page 7 | | |
| UAT-10 | US-06 | View as role "West" | Only West states; totals match a West-only SQL query | | |
| UAT-11 | US-12 | Switch the field parameter | Chart switches between the three rates | | |

## Spot-check query (UAT-03)

| Cut | Report value | SQL value | Match |
|---|---|---|---|
| Grade C, 2016 | (fill in Phase 9) | Loans: 132178, Funded: 1,941,539,800, Default rate: 0.261… | |
| Small business, all years | (fill in Phase 9) | Loans: 19952, Funded: 334,668,200, Default rate: 0.314… | |
| FICO 660-699, DTI 30-40 | (fill in Phase 9) | Loans: 120051, Funded: 1,708,163,575, Default rate: 0.338… | |


Run against `data/warehouse.duckdb` and compare with the report filtered to grade C, 2016:

```sql
select
    count(*) as loans,
    sum(loan_amount) as funded,
    sum(is_default) * 1.0 / nullif(sum(is_closed), 0) as default_rate
from marts.fct_loans
where grade = 'C' and year(issue_date) = 2016;
```

Record three such cuts here with both values before quoting any figure in Key findings.

| Cut | Report value | SQL value | Match |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
