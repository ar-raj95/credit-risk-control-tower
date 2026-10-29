# Risks, assumptions, issues and dependencies

## Risks

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | Proxy data read as representative of a real bank book | Medium | High | Disclaimer in README, report footer and demo | Product owner |
| R2 | Low default rates on young vintages read as good performance | High | High | `is_right_censored` flag, shading and note on Page 3 | Product owner |
| R3 | Illustrative thresholds treated as policy | Medium | Medium | Labelled illustrative in seed, README and demo | Product owner |
| R4 | DAX drifts from dbt definitions over time | Medium | High | DAX only aggregates; reconciliation test and hidden page | Report developer |
| R5 | Real file has formats the fixture does not | Medium | Medium | Safe casts in staging; gates fail loudly; R1 run on real data | Data engineer |
| R6 | Power BI slow on full loan volume | Low | Medium | Column pruning, low-cardinality keys, Performance Analyzer | Report developer |

## Assumptions

| ID | Assumption | Impact if wrong |
|---|---|---|
| A1 | 2015-16 is a fair model development baseline for PSI | PSI levels shift; bands still valid |
| A2 | Loss = funded amount minus principal received on defaults, recoveries excluded | Net loss rate overstated relative to a net-of-recoveries measure |
| A3 | "Charged Off" and "Default" statuses both mean default | Default rate changes if Default is treated as a late stage |
| A4 | A vintage is immature when under 50% of loans have reached term | Different cut-off moves which quarters are flagged |
| A5 | Census regions are a reasonable proxy for regional ownership in RLS | Real roles would use the business's own regions |

## Issues

| ID | Issue | Status | Action |
|---|---|---|---|
| I1 | Pipeline not yet run on the full Kaggle file | Closed 2026-10-29 | Ran on 2,260,701 rows; all gates passed; all statuses mapped |
| I2 | 2,563 loans with DTI outside 0 to 100 (DQ06): 137 placeholder values (135 at 999, 2 at -1) and 2,426 high but plausible values (100 to 995.6) | Open | Confirm placeholder meaning with origination data owner; review high-DTI policy with credit risk |

## Dependencies

| ID | Dependency | Note |
|---|---|---|
| D1 | Kaggle dataset `wordsforthewise/lending-club` | Not stored in repo; check licence terms before redistributing any extract |
| D2 | dbt Core 1.12 and dbt-duckdb 1.11 | Pinned in `requirements.txt`; v2 upgrade on roadmap |
| D3 | Power BI Desktop with .pbip support | Needed for Git-friendly model files |
