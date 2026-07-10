{{
  config(
    materialized      = 'incremental',
    incremental_strategy = 'merge',
    unique_key        = 'journal_entry_id',
    cluster_by        = ['posting_date'],
    on_schema_change  = 'append_new_columns'
  )
}}

with gl as (
    select * from {{ ref('stg_erp__gl_journal_entries') }}
    {% if is_incremental() %}
    where posting_date >= (
        select dateadd(day, -{{ var('incremental_lookback_days', 3) }}, max(posting_date))
        from {{ this }}
    )
    {% endif %}
),

coa as ( select * from {{ ref('dim_chart_of_accounts') }} ),
cc  as ( select * from {{ ref('dim_cost_center') }} ),
le  as ( select * from {{ ref('dim_legal_entity') }} ),
fc  as ( select * from {{ ref('dim_fiscal_calendar') }} ),
fx  as ( select * from {{ ref('stg_treasury__fx_rates') }} )

select
    {{ dbt_utils.generate_surrogate_key(['gl.journal_number', 'gl.line_number', 'gl.company_code']) }}
                                                as journal_entry_id,
    gl.account_number                           as account_id,
    gl.cost_center_code                         as cost_center_id,
    gl.company_code                             as entity_id,
    to_number(to_char(gl.posting_date, 'YYYYMMDD')) as date_key,
    gl.posting_date,
    gl.debit_amount,
    gl.credit_amount,
    gl.debit_amount - gl.credit_amount          as net_amount,
    (gl.debit_amount - gl.credit_amount)
        * coalesce(fx.exchange_rate, 1.0)       as reporting_amount,

    -- Denormalized dimensions
    coa.account_name, coa.account_number, coa.account_category,
    coa.account_sub_category, coa.financial_statement as financial_statement_line,
    coa.is_revenue_account, coa.is_expense_account,
    cc.cost_center_name, cc.department, cc.division, cc.business_unit,
    le.entity_name, le.entity_country,
    fc.fiscal_year, fc.fiscal_quarter, fc.fiscal_period, fc.fiscal_period_name,
    gl.journal_type, gl.source_system, gl.created_at

from gl
left join coa on gl.account_number = coa.account_id
left join cc  on gl.cost_center_code = cc.cost_center_id
left join le  on gl.company_code = le.entity_id
left join fc  on to_number(to_char(gl.posting_date, 'YYYYMMDD')) = fc.date_key
left join fx  on gl.currency_code = fx.from_currency
                 and fx.to_currency = '{{ var("reporting_currency") }}'
                 and date_trunc('month', gl.posting_date) = fx.rate_date
