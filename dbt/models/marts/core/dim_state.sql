-- Region drives row-level security roles in Power BI.

select
    state_code,
    state_name,
    region
from {{ ref('state_region') }}

union all

select
    'UNK' as state_code,
    'Unknown or invalid' as state_name,
    'Unknown' as region
