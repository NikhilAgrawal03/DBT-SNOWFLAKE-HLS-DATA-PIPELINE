{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'member_eligibility') }}
),

renamed as (
    select
        -- Primary key
        eligibility_id,
        
        -- Foreign keys
        member_id,
        plan_id,
        
        -- Coverage dates
        coverage_start_date,
        coverage_end_date,
        
        -- Financial amounts
        premium_amount,
        deductible_amount,
        copay_amount,
        
        -- Status
        is_active,
        
        -- Data quality flags
        case 
            when coverage_end_date is not null 
                and coverage_end_date < coverage_start_date 
            then true 
            else false 
        end as has_invalid_date_range,
        
        case 
            when coverage_end_date is null 
                or coverage_end_date >= current_date 
            then true 
            else false 
        end as is_current_coverage,
        
        -- Metadata
        updated_at,
        current_timestamp() as dbt_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from source
    
    where eligibility_id is not null
)

select * from renamed
