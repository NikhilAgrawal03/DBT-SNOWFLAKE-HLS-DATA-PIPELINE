{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        start_date="'1970-01-01'",
        end_date="current_date",
        datepart="day"
    ) }}
)

select
    date_day as date_day
from date_spine
order by date_day