-- The KRI table and the loan fact must give the same portfolio default rate.
-- Guards against the two definitions drifting apart.

with from_fact as (
    select sum(is_default) * 1.0 / nullif(sum(is_closed), 0) as default_rate
    from {{ ref('fct_loans') }}
),

closed_by_quarter as (
    select
        issue_quarter_key,
        sum(is_closed) as closed
    from {{ ref('fct_loans') }}
    group by issue_quarter_key
),

from_kri as (
    select sum(k.kri_value * q.closed) / sum(q.closed) as default_rate
    from {{ ref('fct_kri_quarterly') }} as k
    inner join closed_by_quarter as q on k.period_key = q.issue_quarter_key
    where k.kri = 'default_rate' and k.kri_value is not null
)

select
    f.default_rate as fact_default_rate,
    k.default_rate as kri_default_rate
from from_fact as f
cross join from_kri as k
where abs(f.default_rate - k.default_rate) > 0.0001
