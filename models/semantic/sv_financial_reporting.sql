-- ============================================================================
-- HYBRID: dbt_semantic_view materialization
-- ============================================================================
-- This model creates a NATIVE Snowflake SEMANTIC VIEW object using the
-- dbt_semantic_view package. It gives you:
--   ✅ dbt governance (git, PRs, CI/CD, lineage)
--   ✅ Snowflake-native query access (any SQL client, Power BI DirectQuery)
--   ✅ Cortex Analyst compatibility (NL queries grounded in this definition)
--   ✅ Zero middleware dependency (no dbt Cloud proxy at query time)
--
-- Run: dbt run --select sv_financial_reporting
-- Result: Creates SEMANTIC VIEW in finance_db.semantic_layer.sv_financial_reporting
-- ============================================================================

{{ config(
    materialized = 'semantic_view',
    schema       = 'semantic_layer',
    tags         = ['semantic_view', 'finance']
) }}

TABLES (

  -- Fact: Journal Entries (core financial fact)
  journal_entries AS (
    SELECT *
    FROM {{ ref('fct_journal_entries') }}
    PRIMARY KEY (journal_entry_id)
    COMMENT = 'GL journal entries at the transaction grain. Each row is a debit/credit posting.'
  ),

  -- Fact: Invoices (revenue sub-ledger)
  invoices AS (
    SELECT *
    FROM {{ ref('fct_invoices') }}
    PRIMARY KEY (invoice_id)
    COMMENT = 'Customer invoices — source of truth for revenue recognition (ASC 606).'
  ),

  -- Fact: Budget & Forecast
  budget AS (
    SELECT *
    FROM {{ ref('fct_budget') }}
    PRIMARY KEY (budget_line_id)
    COMMENT = 'Approved budget and rolling forecast by account, cost center, period.'
  ),

  -- Dimension: Chart of Accounts
  accounts AS (
    SELECT *
    FROM {{ ref('dim_chart_of_accounts') }}
    PRIMARY KEY (account_id)
    COMMENT = 'GL account hierarchy: account → sub-category → category → financial statement line.'
  ),

  -- Dimension: Fiscal Calendar
  fiscal_cal AS (
    SELECT *
    FROM {{ ref('dim_fiscal_calendar') }}
    PRIMARY KEY (date_key)
    COMMENT = 'Fiscal calendar with fiscal year, quarter, period (custom FY start {{ var("fiscal_year_start_month") }}).'
  ),

  -- Dimension: Cost Center
  cost_centers AS (
    SELECT *
    FROM {{ ref('dim_cost_center') }}
    PRIMARY KEY (cost_center_id)
    COMMENT = 'Cost center → department → division → business unit hierarchy.'
  ),

  -- Dimension: Legal Entity
  entities AS (
    SELECT *
    FROM {{ ref('dim_legal_entity') }}
    PRIMARY KEY (entity_id)
    COMMENT = 'Legal entities for multi-entity consolidation with intercompany flags.'
  )
)


RELATIONSHIPS (
  journal_entries(account_id)       REFERENCES accounts(account_id),
  journal_entries(date_key)         REFERENCES fiscal_cal(date_key),
  journal_entries(cost_center_id)   REFERENCES cost_centers(cost_center_id),
  journal_entries(entity_id)        REFERENCES entities(entity_id),
  invoices(date_key)                REFERENCES fiscal_cal(date_key),
  invoices(entity_id)               REFERENCES entities(entity_id),
  budget(account_id)                REFERENCES accounts(account_id),
  budget(cost_center_id)            REFERENCES cost_centers(cost_center_id),
  budget(date_key)                  REFERENCES fiscal_cal(date_key)
)


FACTS (

  -- GL amounts
  journal_entries.debit_amount
    COMMENT = 'Debit in functional currency'
    SYNONYMS = ('debit', 'dr'),

  journal_entries.credit_amount
    COMMENT = 'Credit in functional currency'
    SYNONYMS = ('credit', 'cr'),

  journal_entries.net_amount
    COMMENT = 'Net GL amount (debit - credit)'
    SYNONYMS = ('amount', 'gl amount'),

  journal_entries.reporting_amount
    COMMENT = 'Amount in {{ var("reporting_currency") }}'
    SYNONYMS = ('usd amount', 'reporting amount'),

  -- Invoice amounts
  invoices.invoice_amount
    COMMENT = 'Gross invoice before discounts/returns'
    SYNONYMS = ('gross invoice', 'billed amount'),

  invoices.discount_amount
    COMMENT = 'Trade and volume discounts'
    SYNONYMS = ('discount'),

  invoices.return_amount
    COMMENT = 'Returns and credit notes'
    SYNONYMS = ('returns'),

  -- Budget amounts
  budget.budget_amount
    COMMENT = 'Approved budget for the period'
    SYNONYMS = ('budgeted', 'plan'),

  budget.forecast_amount
    COMMENT = 'Latest rolling forecast'
    SYNONYMS = ('forecast', 'reforecast')
)


DIMENSIONS (

  -- Fiscal Calendar
  fiscal_cal.fiscal_year
    COMMENT = 'Fiscal year (FY2026)'
    SYNONYMS = ('year', 'fy'),

  fiscal_cal.fiscal_quarter
    COMMENT = 'Fiscal quarter (Q1-Q4)'
    SYNONYMS = ('quarter', 'qtr'),

  fiscal_cal.fiscal_period_name
    COMMENT = 'Period name (Apr 2025)'
    SYNONYMS = ('month', 'period'),

  fiscal_cal.calendar_date
    COMMENT = 'Standard date'
    SYNONYMS = ('date', 'posting date'),

  fiscal_cal.is_current_period
    COMMENT = 'Is current open period'
    SYNONYMS = ('current month', 'this period'),

  fiscal_cal.is_ytd
    COMMENT = 'Year-to-date flag'
    SYNONYMS = ('ytd'),

  -- Chart of Accounts
  accounts.account_number
    COMMENT = 'GL account number'
    SYNONYMS = ('gl account', 'account code'),

  accounts.account_name
    COMMENT = 'Account description'
    SYNONYMS = ('account'),

  accounts.account_category
    COMMENT = 'Revenue, COGS, Operating Expense, Other, Tax'
    SYNONYMS = ('category'),

  accounts.financial_statement_line
    COMMENT = 'P&L, Balance Sheet, or Cash Flow'
    SYNONYMS = ('fs line', 'statement'),

  -- Cost Center
  cost_centers.cost_center_name
    COMMENT = 'Department name'
    SYNONYMS = ('department', 'cost center'),

  cost_centers.division
    COMMENT = 'Division rollup'
    SYNONYMS = ('div'),

  cost_centers.business_unit
    COMMENT = 'Segment'
    SYNONYMS = ('bu', 'segment'),

  -- Legal Entity
  entities.entity_name
    COMMENT = 'Company name'
    SYNONYMS = ('company', 'entity'),

  entities.entity_country
    COMMENT = 'Country'
    SYNONYMS = ('jurisdiction'),

  -- Invoice
  invoices.revenue_type
    COMMENT = 'Product, Service, Subscription, License'
    SYNONYMS = ('revenue stream'),

  invoices.customer_name
    COMMENT = 'Customer name'
    SYNONYMS = ('customer', 'client')
)


METRICS (

  -- Revenue
  gross_revenue AS SUM(invoices.invoice_amount)
    COMMENT = 'Gross revenue before discounts/returns'
    SYNONYMS = ('total revenue', 'top line'),

  net_revenue AS SUM(invoices.invoice_amount - invoices.discount_amount - invoices.return_amount)
    COMMENT = 'GAAP net revenue after discounts and returns'
    SYNONYMS = ('revenue', 'net sales'),

  -- P&L
  cogs AS SUM(CASE WHEN accounts.account_category = 'COGS' THEN journal_entries.reporting_amount END)
    COMMENT = 'Cost of Goods Sold (accounts 5000-5999)'
    SYNONYMS = ('cost of sales'),

  gross_profit AS (net_revenue - cogs)
    COMMENT = 'Net Revenue minus COGS'
    SYNONYMS = ('gp'),

  gross_margin_pct AS (gross_profit / NULLIF(net_revenue, 0)) * 100
    COMMENT = 'Gross Margin % — target above 60%'
    SYNONYMS = ('gm%', 'margin'),

  operating_expenses AS SUM(CASE WHEN accounts.account_category = 'Operating Expense' THEN journal_entries.reporting_amount END)
    COMMENT = 'Total OpEx (accounts 6000-8999)'
    SYNONYMS = ('opex'),

  operating_income AS (gross_profit - operating_expenses)
    COMMENT = 'EBIT = Gross Profit - OpEx'
    SYNONYMS = ('ebit'),

  ebitda AS (operating_income + SUM(CASE WHEN accounts.account_name ILIKE '%depreciation%' OR accounts.account_name ILIKE '%amortization%' THEN journal_entries.reporting_amount END))
    COMMENT = 'EBITDA — key profitability metric'
    SYNONYMS = ('earnings before interest tax depreciation amortization'),

  net_income AS SUM(CASE WHEN accounts.financial_statement_line = 'Income Statement' THEN journal_entries.reporting_amount END)
    COMMENT = 'Bottom line net income'
    SYNONYMS = ('net profit', 'earnings'),

  -- Variance
  actual_amount AS SUM(journal_entries.reporting_amount)
    COMMENT = 'Actual GL in reporting currency'
    SYNONYMS = ('actual'),

  budget_total AS SUM(budget.budget_amount)
    COMMENT = 'Approved budget'
    SYNONYMS = ('budget'),

  budget_variance AS (actual_amount - budget_total)
    COMMENT = 'Actual minus Budget'
    SYNONYMS = ('variance', 'avb'),

  budget_variance_pct AS (budget_variance / NULLIF(budget_total, 0)) * 100
    COMMENT = 'Variance as % of budget'
    SYNONYMS = ('variance %'),

  -- Balance Sheet
  working_capital AS (
    SUM(CASE WHEN accounts.account_category = 'Current Assets' THEN journal_entries.net_amount END)
    - SUM(CASE WHEN accounts.account_category = 'Current Liabilities' THEN journal_entries.net_amount END)
  )
    COMMENT = 'Current Assets minus Current Liabilities'
    SYNONYMS = ('nwc'),

  current_ratio AS (
    SUM(CASE WHEN accounts.account_category = 'Current Assets' THEN journal_entries.net_amount END)
    / NULLIF(SUM(CASE WHEN accounts.account_category = 'Current Liabilities' THEN journal_entries.net_amount END), 0)
  )
    COMMENT = 'Liquidity ratio — target > 1.5'
    SYNONYMS = ('liquidity ratio'),

  dso AS (
    SUM(CASE WHEN accounts.account_number LIKE '1200%' THEN journal_entries.net_amount END)
    / NULLIF(net_revenue, 0) * 365
  )
    COMMENT = 'Days Sales Outstanding — target < 45'
    SYNONYMS = ('collection days')
)

COMMENT = 'Governed finance semantic model for P&L, balance sheet, budget variance, and receivables. Managed by dbt CI/CD. Consumed by Power BI (DirectQuery), Cortex Analyst, Excel, and all SQL clients.'
