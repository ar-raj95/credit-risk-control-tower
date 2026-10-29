# Release plan

Each release ends with a working, tested product a stakeholder could use. Effort is in evenings, for a solo build.

| Release | Goal | Stories | Pages | Effort |
|---|---|---|---|---|
| R1 MVP | Trusted KRIs for the executive and analyst | US-01, 02, 07, 08, 09, 10 | 1 Executive, 2 Composition, 3 Vintage | 3 evenings |
| R2 Monitoring | Drift, data quality and self-service | US-03, 04, 05, 12 | 4 Segment, 5 Stability, 6 DQ, 7 Dictionary | 2 evenings |
| R3 Governance | Access, publishing and operating model | US-06, 11 | RLS, docs site, demo | 1 to 2 evenings |

## R1 MVP

**Exit criteria**
- `dbt build` passes on the real Kaggle file, with warnings reviewed and explained.
- Reconciliation tests pass; the hidden reconciliation page shows zero difference for every quarter.
- Pages 1 to 3 built with RAG from the risk appetite table and the immature-vintage note.
- Repo pushed with CI passing.

## R2 Monitoring

**Exit criteria**
- PSI matrix with bin drill-through; DQ scorecard by rule and quarter.
- Every measure in the report has a dictionary entry (checked manually against the measure list).
- Field parameter working on Pages 3 and 4.

## R3 Governance

**Exit criteria**
- RLS roles tested with "View as" for all four regions.
- dbt docs site published to GitHub Pages and linked from the README.
- PDF export, one screenshot per page and a 2-minute demo video in the README.
- Key findings written, each figure reconciled.

## Definition of done (every story)

1. Acceptance criteria met, with evidence linked in the backlog.
2. Logic in dbt, not DAX, unless it is pure aggregation or formatting.
3. New metrics have a dictionary entry; new rules have a catalog entry and owner.
4. `dbt build` and SQLFluff pass in CI.
5. Limitations stated on the page where they apply.

## Release risks

| Risk | Mitigation |
|---|---|
| Real data differs from the fixture (formats, statuses) | Run R1 on the real file first; staging uses safe casts and the status gate fails loudly |
| Power BI performance on about 1.9M loans | Load only needed columns; integer and low-cardinality keys; check with Performance Analyzer |
| Scope creep into model performance or ECL | Kept on the roadmap, out of R1 to R3 |
