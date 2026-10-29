# Power BI guide: connecting the report to the dbt marts

The report reads the Parquet files dbt writes to `data/marts/` after every successful build. Power BI does no business logic: it relates tables, aggregates, and formats. If a number needs a new rule, the rule goes in dbt.

## 1. Load the marts (about 30 minutes)

1. In Power BI Desktop, enable *Options > Preview features > Power BI Project (.pbip) save option* and save into `powerbi/` as `.pbip`, so the model is diff-able in Git.
2. Create a parameter `MartsFolder` (text) pointing to your full path for `data/marts`.
3. For each file, *Get data > Parquet*, then replace the hard-coded path with the parameter in the Advanced Editor:
   `Parquet.Document(File.Contents(MartsFolder & "\fct_loans.parquet"))`
4. Load these tables and rename them to business names:

| Parquet file | Power BI table | Notes |
|---|---|---|
| fct_loans | FactLoans | Loan grain |
| fct_kri_quarterly | FactKRI | Quarter grain, reconciliation anchor |
| fct_psi, fct_psi_bins | FactPSI, FactPSIBins | Quarter grain |
| fct_dq_results | FactDQ | Rule x quarter grain |
| dim_date, dim_quarter | DimDate, DimQuarter | Mark DimDate as date table |
| dim_grade, dim_purpose, dim_state, dim_fico_band, dim_dti_band | Dim* | Set "Sort by column" to sort_order |
| risk_appetite | RiskAppetite | Disconnected |
| metric_dictionary, dq_rule_catalog | MetricDictionary, DQRules | Page 7 and DQ page |

## 2. Relationships

All single direction, one to many:

```
DimQuarter[quarter_key] ─< DimDate[quarter_key]
DimDate[date_day]       ─< FactLoans[issue_date]
DimGrade[grade]         ─< FactLoans[grade]
DimPurpose[purpose]     ─< FactLoans[purpose]
DimState[state_code]    ─< FactLoans[state_code]
DimFICOBand[fico_band]  ─< FactLoans[fico_band]
DimDTIBand[dti_band]    ─< FactLoans[dti_band]
DimQuarter[quarter_key] ─< FactKRI[period_key]
DimQuarter[quarter_key] ─< FactPSI[period_key]
DimQuarter[quarter_key] ─< FactPSIBins[period_key]
DimQuarter[quarter_key] ─< FactDQ[period_key]
DQRules[rule_id]        ─< FactDQ[rule_id]
```

Use `DimQuarter` for period slicers so one slicer filters loans, KRIs, PSI and DQ together. Hide foreign keys and raw numeric columns once measures exist.

## 3. Measures

Put these in a `_Measures` table with display folders matching `metric_dictionary.csv`.

```DAX
-- Exposure
Loan Count    = COUNTROWS ( FactLoans )
Funded Amount = SUM ( FactLoans[loan_amount] )
Avg Loan Size = DIVIDE ( [Funded Amount], [Loan Count] )
Exposure Share =
    DIVIDE ( [Funded Amount], CALCULATE ( [Funded Amount], REMOVEFILTERS ( FactLoans ) ) )

-- Performance (definitions match int_loans_enriched; do not change them here)
Closed Loans     = SUM ( FactLoans[is_closed] )
Defaulted Loans  = SUM ( FactLoans[is_default] )
Default Rate     = DIVIDE ( [Defaulted Loans], [Closed Loans] )
Active Loans     = SUM ( FactLoans[is_active] )
Delinquent Loans = SUM ( FactLoans[is_delinquent] )
Delinquency Rate = DIVIDE ( [Delinquent Loans], [Active Loans] )
Loss Amount      = SUM ( FactLoans[loss_amount] )
Net Loss Rate    = DIVIDE ( [Loss Amount], [Funded Amount] )

-- Credit quality
Avg FICO = AVERAGE ( FactLoans[fico_score] )
Avg DTI  = AVERAGE ( FactLoans[dti] )

-- Stability and data quality
Max PSI      = MAX ( FactPSI[psi] )
DQ Pass Rate = 1 - DIVIDE ( SUM ( FactDQ[failed] ), SUM ( FactDQ[records] ) )

-- One RAG measure for every KRI, driven by the RiskAppetite table
KRI RAG =
VAR _kri = SELECTEDVALUE ( RiskAppetite[kri] )
VAR _value =
    SWITCH ( _kri,
        "default_rate",     [Default Rate],
        "delinquency_rate", [Delinquency Rate],
        "net_loss_rate",    [Net Loss Rate],
        "psi",              [Max PSI],
        "dq_pass_rate",     [DQ Pass Rate] )
VAR _amber = SELECTEDVALUE ( RiskAppetite[amber] )
VAR _red   = SELECTEDVALUE ( RiskAppetite[red] )
VAR _higherIsWorse = SELECTEDVALUE ( RiskAppetite[direction] ) = "higher_is_worse"
RETURN
    SWITCH ( TRUE (),
        ISBLANK ( _value ), BLANK (),
        _higherIsWorse && _value >= _red,     "Red",
        _higherIsWorse && _value >= _amber,   "Amber",
        NOT _higherIsWorse && _value <= _red,   "Red",
        NOT _higherIsWorse && _value <= _amber, "Amber",
        "Green" )
```

For a single KPI card, wrap it: `Default Rate RAG = CALCULATE ( [KRI RAG], RiskAppetite[kri] = "default_rate" )`. Use conditional formatting by field value on the RAG text, not hard-coded colours.

**Dynamic title** for Page 1:

```DAX
Exec Title =
VAR _rag = [Default Rate RAG]
VAR _red = CALCULATE ( SELECTEDVALUE ( RiskAppetite[red] ), RiskAppetite[kri] = "default_rate" )
RETURN "Default rate is " & _rag & ": " & FORMAT ( [Default Rate], "0.0%" )
       & " vs " & FORMAT ( _red, "0%" ) & " red threshold"
```

## 4. Reconciliation page (hidden)

Add a hidden page with a table by `DimQuarter[quarter_label]` showing `[Default Rate]`, the matching `FactKRI[kri_value]` (filtered to `default_rate`), and their difference. Every row should show zero difference. This proves the DAX matches the governed dbt definition, and it is a strong 20 seconds in the demo.

## 5. Governance in the report

- **RLS:** roles on `DimState[region]` (Northeast, Midwest, South, West). Test with *Modeling > View as*. For a per-user version, add a user-to-region mapping seed and filter on `USERPRINCIPALNAME()`.
- **Field parameter:** let users switch one visual between Default Rate, Delinquency Rate and Net Loss Rate.
- **Right-censoring:** on the Vintage page, shade quarters where `FactKRI[is_right_censored]` is true and add a text note.
- **Metric Dictionary page:** table visual on `MetricDictionary`; link to it from a "?" button on every page.
- **Performance:** run Performance Analyzer and screenshot the results for `docs/`.

## 6. Refresh flow

```
load_raw.py  ->  dbt build (tests gate)  ->  data/marts/*.parquet  ->  Power BI refresh
```

Export is all or nothing: if any model or test fails, no Parquet file is overwritten, so the report keeps showing the last complete, tested set. Warnings do not block the export.
