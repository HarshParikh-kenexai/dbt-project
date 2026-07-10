-- Analysis: Monthly P&L reconciliation check
-- Run with: dbt compile --select analyses/monthly_pnl_check
select
    fiscal_year,
    fiscal_period_name,
    sum(case when account_category = 'REVENUE' then reporting_amount else 0 end)            as revenue,
    sum(case when account_category = 'COGS' then reporting_amount else 0 end)               as cogs,
    sum(case when account_category = 'OPERATING EXPENSE' then reporting_amount else 0 end)  as opex,
    revenue - cogs                                                                           as gross_profit,
    revenue - cogs - opex                                                                    as operating_income
from {{ ref('fct_journal_entries') }}
group by 1, 2
order by 1, 2
