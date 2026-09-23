{{ config(materialized='semantic_view') }}

TABLES (
    journal_entries AS {{ ref('fct_journal_entries') }} PRIMARY KEY (journal_entry_id),
    invoices AS {{ ref('fct_invoices') }} PRIMARY KEY (invoice_id),
    budget AS {{ ref('fct_budget') }} PRIMARY KEY (budget_line_id),
    accounts AS {{ ref('dim_chart_of_accounts') }} PRIMARY KEY (account_id),
    cost_centers AS {{ ref('dim_cost_center') }} PRIMARY KEY (cost_center_id),
    entities AS {{ ref('dim_legal_entity') }} PRIMARY KEY (entity_id),
    calendar AS {{ ref('dim_fiscal_calendar') }} PRIMARY KEY (date_key)
)

RELATIONSHIPS (
    journal_to_account AS journal_entries(account_id) REFERENCES accounts(account_id),
    journal_to_cost_center AS journal_entries(cost_center_id) REFERENCES cost_centers(cost_center_id),
    journal_to_entity AS journal_entries(entity_id) REFERENCES entities(entity_id),
    journal_to_calendar AS journal_entries(date_key) REFERENCES calendar(date_key),
    invoice_to_calendar AS invoices(date_key) REFERENCES calendar(date_key),
    invoice_to_entity AS invoices(entity_id) REFERENCES entities(entity_id),
    budget_to_account AS budget(account_id) REFERENCES accounts(account_id),
    budget_to_cost_center AS budget(cost_center_id) REFERENCES cost_centers(cost_center_id),
    budget_to_calendar AS budget(date_key) REFERENCES calendar(date_key)
)

DIMENSIONS (
    accounts.account_name AS accounts.account_name
        WITH SYNONYMS = ('GL account', 'chart of accounts'),
    accounts.account_category AS accounts.account_category
        WITH SYNONYMS = ('account type'),
    accounts.account_sub_category AS accounts.account_sub_category,
    accounts.financial_statement AS accounts.financial_statement
        WITH SYNONYMS = ('financial statement line', 'statement type'),
    cost_centers.cost_center_name AS cost_centers.cost_center_name
        WITH SYNONYMS = ('department name', 'cost center'),
    cost_centers.department AS cost_centers.department,
    cost_centers.division AS cost_centers.division,
    cost_centers.business_unit AS cost_centers.business_unit,
    entities.entity_name AS entities.entity_name
        WITH SYNONYMS = ('company', 'legal entity'),
    entities.entity_country AS entities.entity_country
        WITH SYNONYMS = ('country'),
    calendar.fiscal_year AS calendar.fiscal_year
        WITH SYNONYMS = ('FY', 'year'),
    calendar.fiscal_quarter AS calendar.fiscal_quarter
        WITH SYNONYMS = ('quarter'),
    calendar.fiscal_period_name AS calendar.fiscal_period_name
        WITH SYNONYMS = ('period', 'month'),
    calendar.calendar_date AS calendar.calendar_date
        WITH SYNONYMS = ('date'),
    journal_entries.journal_type AS journal_entries.journal_type,
    journal_entries.source_system AS journal_entries.source_system,
    invoices.revenue_type AS invoices.revenue_type
        WITH SYNONYMS = ('revenue category'),
    invoices.customer_name AS invoices.customer_name
        WITH SYNONYMS = ('client', 'customer'),
    budget.budget_version AS budget.budget_version
        WITH SYNONYMS = ('forecast version')
)

METRICS (
    journal_entries.total_reporting_amount AS SUM(journal_entries.reporting_amount)
        WITH SYNONYMS = ('total GL amount', 'total amount in USD'),
    journal_entries.total_debit AS SUM(journal_entries.debit_amount)
        WITH SYNONYMS = ('total debits'),
    journal_entries.total_credit AS SUM(journal_entries.credit_amount)
        WITH SYNONYMS = ('total credits'),
    journal_entries.net_amount AS SUM(journal_entries.net_amount)
        WITH SYNONYMS = ('net GL amount'),
    journal_entries.journal_entry_count AS COUNT(journal_entries.journal_entry_id)
        WITH SYNONYMS = ('number of journal entries', 'transaction count'),
    invoices.total_invoice_amount AS SUM(invoices.invoice_amount)
        WITH SYNONYMS = ('gross revenue', 'total invoiced'),
    invoices.total_discount AS SUM(invoices.discount_amount)
        WITH SYNONYMS = ('total discounts'),
    invoices.total_returns AS SUM(invoices.return_amount)
        WITH SYNONYMS = ('total returns', 'credit notes'),
    invoices.net_revenue AS SUM(invoices.net_amount_usd)
        WITH SYNONYMS = ('net revenue', 'net invoiced amount'),
    invoices.invoice_count AS COUNT(invoices.invoice_id)
        WITH SYNONYMS = ('number of invoices'),
    budget.total_budget AS SUM(budget.budget_amount)
        WITH SYNONYMS = ('budget total', 'approved budget'),
    budget.total_forecast AS SUM(budget.forecast_amount)
        WITH SYNONYMS = ('forecast total', 'rolling forecast')
)

COMMENT = 'Finance semantic view for Cortex Analyst — covers GL journal entries, invoices, budget, and all dimension lookups'
