-- Portfolio KRIs by issue quarter with RAG status against the risk_appetite seed.
-- This is the reconciliation anchor: DAX measures in Power BI must match it.

with loans as (
    select * from {{ ref('int_loans_enriched') }}
),

by_quarter as (
    select
        issue_quarter_key as period_key,
        issue_quarter as period,
        avg(is_matured) as matured_share,
        count(*) as loan_count,
        sum(loan_amount) as funded_amount,
        cast(sum(is_closed) as bigint) as closed_loans,
        cast(sum(is_default) as bigint) as defaulted_loans,
        cast(sum(is_active) as bigint) as active_loans,
        cast(sum(is_delinquent) as bigint) as delinquent_loans,
        sum(loss_amount) as loss_amount
    from loans
    group by issue_quarter_key, issue_quarter
),

dq as (
    select
        period_key,
        1 - sum(failed) / sum(records) as kri_value
    from {{ ref('fct_dq_results') }}
    group by period_key
),

kri_long as (
    select
        period_key,
        period,
        matured_share,
        'default_rate' as kri,
        defaulted_loans / nullif(closed_loans, 0) as kri_value
    from by_quarter

    union all

    select
        period_key,
        period,
        matured_share,
        'delinquency_rate' as kri,
        delinquent_loans / nullif(active_loans, 0) as kri_value
    from by_quarter

    union all

    select
        period_key,
        period,
        matured_share,
        'net_loss_rate' as kri,
        loss_amount / nullif(funded_amount, 0) as kri_value
    from by_quarter

    union all

    select
        b.period_key,
        b.period,
        b.matured_share,
        'dq_pass_rate' as kri,
        d.kri_value
    from by_quarter as b
    inner join dq as d on b.period_key = d.period_key
)

select
    l.period_key,
    l.period,
    l.kri,
    r.kri_label,
    l.kri_value,
    r.amber,
    r.red,
    case
        when l.kri_value is null then 'n/a'
        when r.direction = 'higher_is_worse' and l.kri_value >= r.red then 'Red'
        when r.direction = 'higher_is_worse' and l.kri_value >= r.amber then 'Amber'
        when r.direction = 'lower_is_worse' and l.kri_value <= r.red then 'Red'
        when r.direction = 'lower_is_worse' and l.kri_value <= r.amber then 'Amber'
        else 'Green'
    end as rag,
    l.matured_share,
    -- A vintage is immature when under half its loans have run their full term,
    -- so nobody reads a low default rate on a young book as good news.
    l.matured_share < 0.5 as is_right_censored
from kri_long as l
inner join {{ ref('risk_appetite') }} as r on l.kri = r.kri
