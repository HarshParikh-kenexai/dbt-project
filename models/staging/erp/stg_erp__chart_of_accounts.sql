with source as (
    select * from {{ source('erp', 'raw_chart_of_accounts') }}
),

cleaned as (
    select
        account_number                  as account_id,
        trim(account_number)            as account_number,
        trim(account_name)              as account_name,
        upper(trim(account_category))   as account_category,
        trim(account_sub_category)      as account_sub_category,
        trim(financial_statement)       as financial_statement,
        upper(trim(normal_balance))     as normal_balance,
        case when account_number between '4000' and '4999' then true else false end as is_revenue_account,
        case when account_number between '6000' and '8999' then true else false end as is_expense_account,
        is_active
    from source
    where is_active = true
)

select * from cleaned
