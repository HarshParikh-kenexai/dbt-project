with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('time_spine_start') ~ "' as date)",
        end_date="cast('" ~ var('time_spine_end') ~ "' as date)"
    ) }}
)

select
    to_number(to_char(cast(date_day as date), 'YYYYMMDD'))  as date_key,
    cast(date_day as date)                                   as calendar_date,
    year(date_day)                                           as calendar_year,
    month(date_day)                                          as calendar_month,
    'Q' || quarter(date_day)                                 as calendar_quarter,

    -- Fiscal year (April start)
    case when month(date_day) >= {{ var('fiscal_year_start_month') }}
         then 'FY' || (year(date_day) + 1)
         else 'FY' || year(date_day)
    end                                                      as fiscal_year,

    case
        when month(date_day) in (4,5,6)    then 'Q1'
        when month(date_day) in (7,8,9)    then 'Q2'
        when month(date_day) in (10,11,12) then 'Q3'
        else 'Q4'
    end                                                      as fiscal_quarter,

    case
        when month(date_day) >= {{ var('fiscal_year_start_month') }}
        then month(date_day) - ({{ var('fiscal_year_start_month') }} - 1)
        else month(date_day) + (13 - {{ var('fiscal_year_start_month') }})
    end                                                      as fiscal_period,

    to_char(date_day, 'Mon YYYY')                            as fiscal_period_name,

    case when to_char(date_day, 'YYYY-MM') = to_char(current_date(), 'YYYY-MM')
         then true else false end                            as is_current_period,

    case
        when month(current_date()) >= {{ var('fiscal_year_start_month') }} then
            date_day between
                date_from_parts(year(current_date()), {{ var('fiscal_year_start_month') }}, 1)
                and current_date()
        else
            date_day between
                date_from_parts(year(current_date()) - 1, {{ var('fiscal_year_start_month') }}, 1)
                and current_date()
    end                                                      as is_ytd

from date_spine
