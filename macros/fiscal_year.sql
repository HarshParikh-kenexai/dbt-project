{% macro fiscal_year(date_column) %}
    case when month({{ date_column }}) >= {{ var('fiscal_year_start_month') }}
         then 'FY' || (year({{ date_column }}) + 1)
         else 'FY' || year({{ date_column }})
    end
{% endmacro %}
