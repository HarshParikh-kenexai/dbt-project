{% macro convert_currency(amount_column, currency_column, date_column) %}
    ({{ amount_column }}) * coalesce(
        (select fx.exchange_rate
         from {{ ref('stg_treasury__fx_rates') }} fx
         where fx.from_currency = {{ currency_column }}
           and fx.to_currency = '{{ var("reporting_currency") }}'
           and fx.rate_date = date_trunc('month', {{ date_column }})
         limit 1),
        1.0
    )
{% endmacro %}
