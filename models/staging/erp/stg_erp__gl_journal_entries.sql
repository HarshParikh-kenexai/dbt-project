with source as (
    select * from {{ source('erp', 'raw_gl_journal_entries') }}
),

cleaned as (
    select
        trim(journal_number)            as journal_number,
        line_number,
        trim(company_code)              as company_code,
        posting_date,
        trim(account_number)            as account_number,
        trim(cost_center_code)          as cost_center_code,
        coalesce(debit_amount, 0)       as debit_amount,
        coalesce(credit_amount, 0)      as credit_amount,
        upper(trim(currency_code))      as currency_code,
        trim(journal_type)              as journal_type,
        trim(description)               as description,
        trim(source_system)             as source_system,
        created_at
    from source
)

select * from cleaned
