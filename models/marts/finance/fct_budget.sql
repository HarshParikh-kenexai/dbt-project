-- Full refresh — forecasts overwrite prior versions
with bud as ( select * from {{ ref('stg_planning__budget') }} ),
coa as ( select * from {{ ref('dim_chart_of_accounts') }} ),
cc  as ( select * from {{ ref('dim_cost_center') }} ),
fc  as ( select * from {{ ref('dim_fiscal_calendar') }} )

select
    bud.budget_id                                        as budget_line_id,
    bud.budget_version,
    bud.fiscal_period_start                              as budget_date,
    to_number(to_char(bud.fiscal_period_start, 'YYYYMMDD')) as date_key,
    bud.account_number                                   as account_id,
    bud.cost_center_code                                 as cost_center_id,
    bud.budget_amount, bud.forecast_amount,
    coa.account_name, coa.account_category,
    cc.cost_center_name, cc.division,
    fc.fiscal_year, fc.fiscal_quarter, fc.fiscal_period_name

from bud
left join coa on bud.account_number = coa.account_id
left join cc  on bud.cost_center_code = cc.cost_center_id
left join fc  on to_number(to_char(bud.fiscal_period_start, 'YYYYMMDD')) = fc.date_key
