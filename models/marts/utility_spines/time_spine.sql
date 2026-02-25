{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="DATE('2000-01-01')",
        end_date="current_date"
    ) }}
)
select cast(date_day as date) as date_day
from date_spine
order by 1;
``