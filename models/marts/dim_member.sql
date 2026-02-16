{{
    config(
        materialized='table',
        tags=['dimension', 'pii']
    )
}}

with members as (
    select * from {{ ref('stg_members') }}
),

current_eligibility as (
    select * from {{ ref('int_member_eligibility_current') }}
),

member_dim as (
    select
        -- Surrogate key (using member_id as natural key)
        {{ dbt_utils.generate_surrogate_key(['m.member_id']) }} as member_key,
        
        -- Natural key
        m.member_id,
        
        -- Type 1 attributes (updated in place)
        m.first_name,
        m.last_name,
        m.date_of_birth,
        m.current_age,
        
        -- Demographic attributes
        m.gender,
        
        -- Location attributes
        m.address,
        m.city,
        m.state,
        m.zip_code,
        
        -- Contact attributes
        m.phone,
        m.email,
        
        -- Enrollment attributes
        m.enrollment_date,
        m.years_enrolled,
        m.member_status,
        
        -- Current plan information
        e.plan_id as current_plan_id,
        e.coverage_start_date as current_coverage_start_date,
        e.premium_amount as current_premium_amount,
        e.deductible_amount as current_deductible_amount,
        
        -- Age bands for analytics
        case
            when m.current_age < 18 then '0-17'
            when m.current_age < 30 then '18-29'
            when m.current_age < 40 then '30-39'
            when m.current_age < 50 then '40-49'
            when m.current_age < 65 then '50-64'
            else '65+'
        end as age_band,
        
        -- Metadata
        current_timestamp() as dim_created_at,
        current_timestamp() as dim_updated_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from members m
    left join current_eligibility e on m.member_id = e.member_id
)

select * from member_dim
