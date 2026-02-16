{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'claims') }}
),

deduplicated as (
    select 
        *,
        row_number() over (
            partition by claim_id 
            order by loaded_at desc
        ) as row_num
    from source
),

renamed as (
    select
        -- Primary key
        claim_id,
        
        -- Foreign keys
        member_id,
        provider_id,
        
        -- Claim information
        claim_type,
        service_date,
        submitted_date,
        
        -- Clinical codes
        upper(trim(diagnosis_code)) as diagnosis_code,
        upper(trim(procedure_code)) as procedure_code,
        
        -- Financial amounts
        billed_amount,
        allowed_amount,
        paid_amount,
        
        -- Derived financial metrics
        billed_amount - allowed_amount as network_discount,
        allowed_amount - paid_amount as member_responsibility,
        case 
            when allowed_amount > 0 
            then round((paid_amount / allowed_amount) * 100, 2)
            else 0 
        end as paid_percentage,
        
        -- Status and timing
        claim_status,
        {{ dbt.datediff('service_date', 'submitted_date', 'day') }} as days_to_submit,
        
        -- Late arrival flag (claims submitted >30 days after service)
        case 
            when {{ dbt.datediff('service_date', 'submitted_date', 'day') }} > 30 
            then true 
            else false 
        end as is_late_arrival,
        
        -- Metadata
        loaded_at,
        current_timestamp() as dbt_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from deduplicated
    
    -- Take most recent record for each claim_id
    where row_num = 1
      and claim_id is not null
)

select * from renamed
