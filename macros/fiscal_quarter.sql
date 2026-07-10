{% macro fiscal_quarter(date_column) %}
    case
        when month({{ date_column }}) in (4,5,6)    then 'Q1'
        when month({{ date_column }}) in (7,8,9)    then 'Q2'
        when month({{ date_column }}) in (10,11,12) then 'Q3'
        else 'Q4'
    end
{% endmacro %}
