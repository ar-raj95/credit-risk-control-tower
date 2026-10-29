-- Apply business rules once, here, so every downstream output agrees:
-- deduplication, status flags, credit bands, loss and vintage maturity.

with loans as (
    select *
    from {{ ref('stg_lendingclub__loans') }}
    -- Duplicates are counted by DQ10; keep the latest-loaded copy.
    qualify row_number() over (partition by loan_id order by _loaded_at desc) = 1
),

status_map as (select * from {{ ref('loan_status_map') }}),

fico_bands as (select * from {{ ref('fico_bands') }}),

dti_bands as (select * from {{ ref('dti_bands') }}),

enriched as (
    select
        l.*,
        (l.fico_range_low + l.fico_range_high) / 2.0 as fico_score,
        s.status_group,
        s.is_default,
        s.is_closed,
        s.is_active,
        s.is_delinquent,
        case
            when s.is_default = 1
                then greatest(l.loan_amount - coalesce(l.principal_received, 0), 0)
            else 0
        end as loss_amount,
        {{ quarter_label('l.issue_date') }} as issue_quarter,
        {{ quarter_key('l.issue_date') }} as issue_quarter_key,
        year(l.issue_date) as issue_year,
        -- Right-censoring: a vintage is mature only once its full term has run.
        case
            when
                l.issue_date + to_months(l.term_months)
                <= cast('{{ var("data_cutoff_date") }}' as date) then 1
            else 0
        end as is_matured
    from loans as l
    left join status_map as s on l.loan_status = s.loan_status
)

select
    e.*,
    coalesce(f.fico_band, 'Unknown') as fico_band,
    coalesce(d.dti_band, 'Unknown') as dti_band
from enriched as e
left join fico_bands as f
    on e.fico_score >= f.lower_bound and e.fico_score < f.upper_bound
left join dti_bands as d
    on e.dti >= d.lower_bound and e.dti < d.upper_bound
