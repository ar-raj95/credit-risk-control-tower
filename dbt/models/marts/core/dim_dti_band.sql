select
    dti_band,
    sort_order
from {{ ref('dti_bands') }}

union all

select
    'Unknown' as dti_band,
    99 as sort_order
