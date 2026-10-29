# Product vision

## Vision statement

For **credit risk, model risk and data governance teams** who need to know whether the portfolio is inside risk appetite, the **Credit Risk Control Tower** is a governed monitoring product that gives **one trusted set of numbers**. Unlike spreadsheet packs and stand-alone dashboards, every metric is defined once, tested on every refresh and traceable from source to report.

## Why now

A risk transformation programme changes how numbers are produced, not just how they look. Four problems usually come first:

| Problem | Consequence | What the product does |
|---|---|---|
| KRIs calculated in several places | Two reports disagree in the same meeting | One definition per KRI, in version-controlled code |
| Data quality found late | Errors reach senior stakeholders | 12 rules measured every run; failing gates block the refresh |
| Model population drift goes unnoticed | Model performance drops before anyone reacts | PSI per feature and quarter against a fixed baseline |
| Analysts are the reporting bottleneck | Slow answers, inconsistent ad hoc cuts | Self-serve report with definitions on the page and in the docs site |

## Users

| Persona | Primary question | Primary page |
|---|---|---|
| Head of Credit Risk | Are we inside risk appetite? | 1 Executive Summary |
| Credit Risk Analyst | Where is risk building? | 2 Composition, 3 Vintage, 4 Segment |
| Model Risk reviewer | Has the population moved away from the model's baseline? | 5 Population Stability |
| Data Steward | Which rules fail, where, and is it getting worse? | 6 DQ Scorecard |
| Any business user | What does this number mean and who owns it? | 7 Metric Dictionary, dbt docs site |
| Regional Manager | How is my region doing? | All pages, filtered by RLS |

## Success measures

Targets a real deployment would track. The project demonstrates the mechanism for each.

| Outcome | Measure | Target | How it is measured here |
|---|---|---|---|
| Trusted numbers | Report KRIs that reconcile to source | 100% within 0.1% | `assert_fct_loans_reconciles_to_source`, `assert_kri_matches_loan_fact`, hidden reconciliation page |
| Shared definitions | Report metrics with a dictionary entry | 100% | `metric_dictionary.csv` vs measures in the report |
| Early detection | Refreshes that publish data failing a blocking test | 0 | All-or-nothing Parquet export; CI history |
| Drift visibility | Model features monitored for PSI | 5 of 5 key inputs | `fct_psi` |
| Self-service | Ad hoc KRI requests to analysts | 50% fewer after 3 months | Would be tracked through the request log (not available in a portfolio project) |
| Adoption | Monthly active report users in target personas | 80% of named users | Would be tracked with Power BI usage metrics |

## Scope

**In scope:** portfolio KRIs, vintage and segment analysis, PSI on 5 model inputs, 12 data quality rules, metric dictionary, RLS by region, automated tests and CI.

**Out of scope for now:** model performance monitoring (Gini, KS), IFRS 9 ECL staging, real-time data, write-back of thresholds from the report. These sit on the roadmap.

## Principles

1. **Logic lives upstream.** Power BI aggregates and formats. Business rules live in dbt where they are tested.
2. **Rules are reviewed config.** Thresholds, mappings and DQ rules change through a pull request, not a DAX edit.
3. **Show the limitations.** Immature vintages, proxy data and illustrative thresholds are labelled in the report, not hidden.
4. **Fail closed.** If a blocking test fails, the report keeps the last good data rather than showing new data that failed checks.
