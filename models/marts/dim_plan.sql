{{
    config(
        materialized='table',
        tags=['dimension']
    )
}}

with eligibility as (
    select * from {{ ref('stg_member_eligibility') }}
),

plan_details as (
    select
        plan_id,
        
        -- Aggregate stats per plan
        count(distinct member_id) as total_members,
        avg(premium_amount) as avg_premium_amount,
        avg(deductible_amount) as avg_deductible_amount,
        avg(copay_amount) as avg_copay_amount,
        min(coverage_start_date) as plan_inception_date,
        
        -- Active members
        count(distinct case when is_active then member_id end) as active_members
        
    from eligibility
    group by plan_id
),

plan_dim as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['plan_id']) }} as plan_key,
        
        -- Natural key
        plan_id,
        
        -- Derived plan attributes based on naming patterns
        case
            when upper(plan_id) like '%PLATINUM%' then 'Platinum'
            when upper(plan_id) like '%GOLD%' then 'Gold'
            when upper(plan_id) like '%SILVER%' then 'Silver'
            when upper(plan_id) like '%BRONZE%' then 'Bronze'
            else 'Other'
        end as plan_tier,
        
        case
            when upper(plan_id) like '%HMO%' then 'HMO'
            when upper(plan_id) like '%PPO%' then 'PPO'
            when upper(plan_id) like '%EPO%' then 'EPO'
            when upper(plan_id) like '%POS%' then 'POS'
            else 'Unknown'
        end as plan_type,
        
        -- Aggregated metrics
        total_members,
        active_members,
        avg_premium_amount,
        avg_deductible_amount,
        avg_copay_amount,
        plan_inception_date,
        
        -- Tier rankings
        case
            when upper(plan_id) like '%PLATINUM%' then 1
            when upper(plan_id) like '%GOLD%' then 2
            when upper(plan_id) like '%SILVER%' then 3
            when upper(plan_id) like '%BRONZE%' then 4
            else 5
        end as tier_rank,
        
        -- Metadata
        current_timestamp() as dim_created_at,
        current_timestamp() as dim_updated_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from plan_details
)

select * from plan_dim
