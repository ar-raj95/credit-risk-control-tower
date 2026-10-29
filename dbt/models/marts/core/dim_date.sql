-- Daily calendar covering the loan book. Quarter keys match FactDQ and FactPSI.

with bounds as (
    select
        make_date(year(min(issue_date)), 1, 1) as start_date,
        make_date(year(max(issue_date)), 12, 31) as end_date
    from {{ ref('int_loans_enriched') }}
),

days as (
    select cast(unnest(generate_series(start_date, end_date, interval 1 day)) as date) as date_day
    from bounds
)

select
    date_day,
    year(date_day) as calendar_year,
    quarter(date_day) as calendar_quarter,
    month(date_day) as calendar_month,
    strftime(date_day, '%b %Y') as month_label,
    year(date_day) * 100 + month(date_day) as month_key,
    {{ quarter_label('date_day') }} as quarter_label,
    {{ quarter_key('date_day') }} as quarter_key
from days
