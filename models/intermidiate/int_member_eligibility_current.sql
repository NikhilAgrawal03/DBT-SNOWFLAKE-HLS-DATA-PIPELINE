{{
    config(
        materialized='ephemeral'
    )
}}

with eligibility as (
    select * from {{ ref('stg_member_eligibility') }}
),

-- Get most recent record per member
current_eligibility as (
    select
        *,
        row_number() over (
            partition by member_id 
            order by coverage_start_date desc, updated_at desc
        ) as recency_rank
    from eligibility
    where is_current_coverage = true
      and has_invalid_date_range = false
),

final as (
    select
        eligibility_id,
        member_id,
        plan_id,
        coverage_start_date,
        coverage_end_date,
        premium_amount,
        deductible_amount,
        copay_amount,
        is_active,
        is_current_coverage,
        updated_at,
        dbt_loaded_at
    from current_eligibility
    where recency_rank = 1
)

select * from final
