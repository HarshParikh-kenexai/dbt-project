-- Net revenue should be positive (credit balance for revenue accounts)
select
    fiscal_period_name,
    sum(net_amount_usd) as period_revenue
from {{ ref('fct_invoices') }}
group by fiscal_period_name
having sum(net_amount_usd) < 0
