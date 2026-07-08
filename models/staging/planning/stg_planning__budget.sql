with source as (
    select * from {{ source('planning', 'raw_budget') }}
),

cleaned as (
    select
        trim(budget_id)                     as budget_id,
        trim(budget_version)                as budget_version,
        fiscal_period_start,
        trim(account_number)                as account_number,
        trim(cost_center_code)              as cost_center_code,
        coalesce(budget_amount, 0)          as budget_amount,
        coalesce(forecast_amount, 0)        as forecast_amount,
        upper(trim(currency_code))          as currency_code
    from source
)

select * from cleaned
