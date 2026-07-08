{{
  config(
    materialized      = 'incremental',
    incremental_strategy = 'merge',
    unique_key        = 'invoice_id',
    cluster_by        = ['invoice_date']
  )
}}

with inv as (
    select * from {{ ref('stg_billing__invoices') }}
    {% if is_incremental() %}
    where invoice_date >= (
        select dateadd(day, -{{ var('incremental_lookback_days', 3) }}, max(invoice_date))
        from {{ this }}
    )
    {% endif %}
),

le as ( select * from {{ ref('dim_legal_entity') }} ),
fc as ( select * from {{ ref('dim_fiscal_calendar') }} ),
fx as ( select * from {{ ref('stg_treasury__fx_rates') }} )

select
    inv.invoice_number                              as invoice_id,
    inv.invoice_date,
    to_number(to_char(inv.invoice_date, 'YYYYMMDD')) as date_key,
    inv.customer_id, inv.customer_name,
    inv.company_code                                as entity_id,
    inv.revenue_type,
    inv.invoice_amount, inv.discount_amount, inv.return_amount,
    inv.invoice_amount - inv.discount_amount - inv.return_amount as net_amount,
    (inv.invoice_amount - inv.discount_amount - inv.return_amount)
        * coalesce(fx.exchange_rate, 1.0)           as net_amount_usd,
    inv.currency_code, inv.payment_terms,
    le.entity_name, le.entity_country,
    fc.fiscal_year, fc.fiscal_quarter, fc.fiscal_period_name,
    inv.created_at

from inv
left join le on inv.company_code = le.entity_id
left join fc on to_number(to_char(inv.invoice_date, 'YYYYMMDD')) = fc.date_key
left join fx on inv.currency_code = fx.from_currency
                and fx.to_currency = '{{ var("reporting_currency") }}'
                and date_trunc('month', inv.invoice_date) = fx.rate_date
