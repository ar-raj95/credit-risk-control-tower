# Product backlog

Priority uses MoSCoW. Value and effort are scored 1 to 5; the score is value divided by effort, used to order stories within a priority. "Evidence" points to the automated test or report element that proves the acceptance criteria.

## Epics

| Epic | Goal | Stories |
|---|---|---|
| E1 Trusted data foundation | Raw data typed, cleaned and tested once | US-07, US-08, US-09 |
| E2 Portfolio monitoring | KRIs against risk appetite, by segment and vintage | US-01, US-02, US-10 |
| E3 Model and population stability | Detect drift in model inputs | US-03 |
| E4 Data quality | Measure and act on data defects | US-04, US-11 |
| E5 Enablement and access | Self-service with appropriate access | US-05, US-06, US-12 |

## Stories

### US-01 Headline KRIs against risk appetite (Must)
*As Head of Credit Risk, I want headline KRIs shown against risk appetite so I can see breaches at a glance.*

- **Given** the risk appetite thresholds in `risk_appetite.csv`, **when** the Executive Summary loads, **then** each KRI shows a Red, Amber or Green status.
- **Given** a threshold changes in the seed, **when** the pipeline runs, **then** the RAG status updates with no DAX change.
- **Then** each KPI card has a tooltip with its definition from the metric dictionary.

Value 5 · Effort 2 · Score 2.5 · Release R1 · Evidence: `fct_kri_quarterly`, `KRI RAG` measure, UAT-01 and UAT-02

### US-02 Slice default rate by segment and vintage (Must)
*As a Credit Risk Analyst, I want default rate by grade, purpose and vintage so I can locate where risk is building.*

- **Then** slicers for grade, purpose, state and quarter cross-filter every visual on Pages 2 to 4.
- **Then** loan count and funded amount in the report reconcile to source within 0.1%.
- **Then** report default rate by quarter equals `fct_kri_quarterly` for every quarter.

Value 5 · Effort 3 · Score 1.7 · Release R1 · Evidence: `assert_fct_loans_reconciles_to_source`, `assert_kri_matches_loan_fact`, UAT-03 and UAT-04

### US-03 Population stability by feature (Should)
*As a Model Risk reviewer, I want PSI per feature by quarter so I can see drift before model performance drops.*

- **Then** PSI is calculated for FICO, DTI, income, loan amount and interest rate against the 2015-16 baseline.
- **Then** status bands come from the `psi` row in `risk_appetite.csv` (0.10 and 0.25).
- **Then** a user can drill from a feature and quarter to the 10 baseline deciles to see which part of the distribution moved.

Value 4 · Effort 3 · Score 1.3 · Release R2 · Evidence: `fct_psi`, `fct_psi_bins`, PSI tests, UAT-07

### US-04 DQ pass rates over time (Must)
*As a Data Steward, I want DQ rule pass rates over time so I can prioritize remediation.*

- **Then** each rule shows its ID, dimension, severity and remediation owner.
- **Then** pass rate and failing record count are shown by quarter.
- **Given** a new rule is added to `dq_rule_catalog.csv`, **when** the pipeline runs, **then** it appears in the scorecard with no model change.

Value 4 · Effort 2 · Score 2.0 · Release R2 · Evidence: `fct_dq_results`, UAT-08

### US-05 Definitions where users work (Should)
*As a business user, I want metric definitions inside the report so I don't need to ask an analyst.*

- **Then** every measure on a report page has a row in `metric_dictionary.csv`.
- **Then** Page 7 shows definition, formula, source, owner and refresh, and each page has a "?" link to it.
- **Then** the same definitions are published on the dbt docs site.

Value 3 · Effort 1 · Score 3.0 · Release R2 · Evidence: Page 7, docs site, UAT-09

### US-06 Regional access (Could)
*As a Regional Manager, I want to see only my region's data so access is appropriate.*

- **Then** RLS roles exist for Northeast, Midwest, South and West on `DimState[region]`.
- **Then** "View as" each role shows only that region's loans and totals match a filtered source query.

Value 3 · Effort 2 · Score 1.5 · Release R3 · Evidence: UAT-10

### US-07 Block unclassified data (Must)
*As a Data Steward, I want unmapped or invalid source data to stop the refresh so wrong numbers never reach executives.*

- **Given** a loan status not in `loan_status_map.csv`, **when** the pipeline runs, **then** the build fails and downstream models are skipped.
- **Then** no Parquet file is overwritten, so the report keeps the last good data.
- **Then** the failure is visible in the CI run.

Value 5 · Effort 2 · Score 2.5 · Release R1 · Evidence: relationships test on `stg_lendingclub__loans.loan_status`, export macro, UAT-05

### US-08 Business rules proven by test (Must)
*As a Head of Credit Risk, I want the default, loss and maturity rules tested so I can rely on them.*

- **Then** a unit test with hand-built loans proves status flags, principal loss, FICO and DTI bands, and the maturity flag.

Value 4 · Effort 1 · Score 4.0 · Release R1 · Evidence: unit test `status_flags_loss_and_bands`

### US-09 Stable data contract for the report (Should)
*As a report developer, I want the loan table's columns and types fixed so upstream changes can't silently break the report.*

- **Then** `fct_loans` has an enforced contract; a type or column change fails the build.

Value 3 · Effort 1 · Score 3.0 · Release R1 · Evidence: contract in `_core.yml`

### US-10 Flag immature vintages (Should)
*As a Credit Risk Analyst, I want young vintages flagged so their low default rates are not read as good performance.*

- **Then** vintages where under 50% of loans have reached term are flagged and shaded on the Vintage page with an explanatory note.

Value 4 · Effort 1 · Score 4.0 · Release R1 · Evidence: `is_right_censored`, UAT-06

### US-11 Gate severity per rule (Could)
*As a Data Steward, I want to decide which DQ rules block a refresh and which only report, so blocking is proportionate.*

- **Then** each rule has a gate level (Block, Warn, Report) recorded in the rulebook, and blocking rules are implemented as dbt tests with severity error.

Value 3 · Effort 2 · Score 1.5 · Release R3 · Evidence: DQ rulebook

### US-12 Metric switcher (Could)
*As a Credit Risk Analyst, I want to switch one chart between default, delinquency and net loss rate so I can compare without extra pages.*

- **Then** a field parameter switches the measure on the Vintage and Segment pages.

Value 2 · Effort 1 · Score 2.0 · Release R2 · Evidence: UAT-11

## Ordered backlog

| Rank | ID | Story | Priority | Score | Release |
|---|---|---|---|---|---|
| 1 | US-08 | Business rules proven by test | Must | 4.0 | R1 |
| 2 | US-01 | Headline KRIs against risk appetite | Must | 2.5 | R1 |
| 3 | US-07 | Block unclassified data | Must | 2.5 | R1 |
| 4 | US-02 | Slice by segment and vintage | Must | 1.7 | R1 |
| 5 | US-10 | Flag immature vintages | Should | 4.0 | R1 |
| 6 | US-09 | Stable data contract | Should | 3.0 | R1 |
| 7 | US-04 | DQ pass rates over time | Must | 2.0 | R2 |
| 8 | US-05 | Definitions where users work | Should | 3.0 | R2 |
| 9 | US-03 | Population stability | Should | 1.3 | R2 |
| 10 | US-12 | Metric switcher | Could | 2.0 | R2 |
| 11 | US-06 | Regional access | Could | 1.5 | R3 |
| 12 | US-11 | Gate severity per rule | Could | 1.5 | R3 |
