{% docs loss_amount %}
Principal loss on a defaulted loan: funded amount minus principal received,
floored at zero. Recoveries are excluded, so this is a gross principal loss
approximation, not an accounting write-off. Zero for non-defaulted loans.
{% enddocs %}

{% docs right_censoring %}
1 if the loan's full term ended on or before the data cutoff (2018-12-31).
Loans from immature vintages are still running, so their observed default
rate is understated. Read 2016-2018 vintages with this in mind.
{% enddocs %}

{% docs psi %}
Population Stability Index per feature and quarter, comparing each quarter
issued after the baseline (2015-16) with the baseline distribution over 10
baseline deciles. Bands follow the industry convention used by model risk
teams: below 0.10 stable, 0.10 to 0.25 moderate shift, 0.25 and above
significant shift. Thresholds come from the risk_appetite seed.
{% enddocs %}

{% docs __overview__ %}
# Credit Risk Control Tower: data pipeline

Governed transformation layer for the Credit Risk Control Tower Power BI
report. Raw LendingClub data (public proxy for a retail lending book) is
landed as text, typed in staging, enriched once in intermediate, and
published as tested, contracted marts that Power BI reads as Parquet.

- **Business rules live in seeds** (status map, bands, risk appetite, DQ
  rules), so changes go through review rather than into DAX.
- **Every KRI reconciles**: singular tests check the marts against staging
  and against each other on every build.
- **Data quality is measured, not hidden**: rules run on staging before
  cleaning, so the scorecard shows what the source actually sent.

Illustrative thresholds. No employer or client data.
{% enddocs %}
