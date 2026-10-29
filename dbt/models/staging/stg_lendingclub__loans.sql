-- Type and rename the raw extract. No business rules here: values that fail
-- to cast become null, so data-quality rules can count them downstream.

with source as (
    select * from {{ source('lendingclub', 'lendingclub_loans') }}
),

typed as (
    select
        try_cast(id as bigint) as loan_id,
        try_cast(loan_amnt as double) as loan_amount,
        try_cast(regexp_extract(term, '(\d+)', 1) as integer) as term_months,
        try_cast(replace(int_rate, '%', '') as double) as interest_rate_pct,
        try_cast(installment as double) as installment,
        nullif(trim(grade), '') as grade,
        nullif(trim(sub_grade), '') as sub_grade,
        nullif(trim(emp_length), '') as emp_length,
        nullif(trim(home_ownership), '') as home_ownership,
        try_cast(annual_inc as double) as annual_income,
        nullif(trim(verification_status), '') as verification_status,
        cast(try_strptime(issue_d, '%b-%Y') as date) as issue_date,
        trim(loan_status) as loan_status,
        nullif(trim(purpose), '') as purpose,
        upper(nullif(trim(addr_state), '')) as state_code,
        try_cast(dti as double) as dti,
        try_cast(delinq_2yrs as integer) as delinquencies_2yrs,
        try_cast(fico_range_low as integer) as fico_range_low,
        try_cast(fico_range_high as integer) as fico_range_high,
        try_cast(replace(revol_util, '%', '') as double) as revol_util_pct,
        try_cast(open_acc as integer) as open_accounts,
        try_cast(total_pymnt as double) as total_payment,
        try_cast(total_rec_prncp as double) as principal_received,
        try_cast(recoveries as double) as recoveries,
        _loaded_at
    from source
)

select *
from typed
-- Footer and summary rows in the Kaggle file have no loan amount or date.
where
    loan_amount is not null
    and issue_date >= make_date({{ var('start_year') }}, 1, 1)
