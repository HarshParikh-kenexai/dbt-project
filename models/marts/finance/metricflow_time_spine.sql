{{ config(materialized = 'table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('time_spine_start') ~ "' as date)",
        end_date="cast('" ~ var('time_spine_end') ~ "' as date)"
    ) }}
)
select cast(date_day as date) as ds from date_spine
