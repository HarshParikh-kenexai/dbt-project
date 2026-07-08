with source as (
    select * from {{ source('treasury', 'raw_fx_rates') }}
),

cleaned as (
    select
        rate_date,
        upper(trim(from_currency))  as from_currency,
        upper(trim(to_currency))    as to_currency,
        exchange_rate,
        upper(trim(rate_type))      as rate_type
    from source
)

select * from cleaned
