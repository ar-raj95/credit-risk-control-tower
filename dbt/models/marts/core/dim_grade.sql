select distinct
    grade,
    'Grade ' || grade as grade_label,
    ascii(grade) - ascii('A') + 1 as sort_order
from {{ ref('int_loans_enriched') }}
where grade is not null
