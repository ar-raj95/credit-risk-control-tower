-- PSI per feature and monitoring quarter, with status from the risk_appetite seed.

with psi as (
    select
        feature,
        period_key,
        period,
        sum(psi_contribution) as psi
    from {{ ref('fct_psi_bins') }}
    group by all
),

thresholds as (
    select
        amber,
        red
    from {{ ref('risk_appetite') }}
    where kri = 'psi'
)

select
    p.feature,
    p.period_key,
    p.period,
    p.psi,
    case
        when p.psi >= t.red then 'Significant shift'
        when p.psi >= t.amber then 'Moderate shift'
        else 'Stable'
    end as psi_status,
    case
        when p.psi >= t.red then 'Red'
        when p.psi >= t.amber then 'Amber'
        else 'Green'
    end as rag
from psi as p
cross join thresholds as t
