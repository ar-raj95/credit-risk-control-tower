select
    fico_band,
    sort_order
from {{ ref('fico_bands') }}

union all

select
    'Unknown' as fico_band,
    99 as sort_order
