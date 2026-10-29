-- Loan-level fact for Power BI. One row per unique loan; keys join to the dims.

select
    l.loan_id,
    l.issue_date,
    l.issue_quarter_key,
    l.grade,
    l.sub_grade,
    l.purpose,
    case when s.state_code is null then 'UNK' else l.state_code end as state_code,
    l.fico_band,
    l.dti_band,
    l.term_months,
    l.home_ownership,
    l.verification_status,
    l.status_group,
    l.loan_amount,
    l.interest_rate_pct,
    l.annual_income,
    l.dti,
    l.fico_score,
    l.loss_amount,
    l.is_default,
    l.is_closed,
    l.is_active,
    l.is_delinquent,
    l.is_matured
from {{ ref('int_loans_enriched') }} as l
left join {{ ref('state_region') }} as s on l.state_code = s.state_code
