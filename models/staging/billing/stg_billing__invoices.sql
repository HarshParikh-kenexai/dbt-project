with source as (
    select * from {{ source('billing', 'raw_invoices') }}
),

cleaned as (
    select
        trim(invoice_number)            as invoice_number,
        invoice_date,
        trim(customer_id)               as customer_id,
        trim(customer_name)             as customer_name,
        trim(company_code)              as company_code,
        trim(revenue_type)              as revenue_type,
        coalesce(invoice_amount, 0)     as invoice_amount,
        coalesce(discount_amount, 0)    as discount_amount,
        coalesce(return_amount, 0)      as return_amount,
        upper(trim(currency_code))      as currency_code,
        trim(payment_terms)             as payment_terms,
        created_at
    from source
)

select * from cleaned
