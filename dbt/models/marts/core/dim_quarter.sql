-- One row per quarter. Bridges quarter-grain facts (DQ, PSI, KRI) to DimDate.

select distinct
    quarter_key,
    quarter_label,
    calendar_year,
    calendar_quarter
from {{ ref('dim_date') }}
