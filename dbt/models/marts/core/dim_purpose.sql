select distinct
    purpose,
    upper(left(replace(purpose, '_', ' '), 1))
    || substr(replace(purpose, '_', ' '), 2) as purpose_label
from {{ ref('int_loans_enriched') }}
where purpose is not null
