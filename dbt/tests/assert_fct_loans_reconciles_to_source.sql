-- Reconciliation: loan count and funded amount in the mart must match the
-- distinct loans in staging. Returns a row (fails) if they differ by more than 0.1%.

with source as (
    select
        count(distinct loan_id) as loans,
        sum(loan_amount) as funded
    from (
        select
            loan_id,
            any_value(loan_amount) as loan_amount
        from {{ ref('stg_lendingclub__loans') }}
        group by loan_id
    )
),

mart as (
    select
        count(*) as loans,
        sum(loan_amount) as funded
    from {{ ref('fct_loans') }}
)

select
    s.loans as source_loans,
    m.loans as mart_loans,
    s.funded as source_funded,
    m.funded as mart_funded
from source as s cross join mart as m
where
    s.loans != m.loans
    or abs(s.funded - m.funded) / nullif(s.funded, 0) > 0.001
