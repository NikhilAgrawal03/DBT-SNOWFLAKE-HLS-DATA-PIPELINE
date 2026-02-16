{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'provider_network_status') }}
),

renamed as (
    select
        -- Primary key
        network_status_id,
        
        -- Foreign keys
        provider_id,
        network_id,
        
        -- Network status
        network_status,
        
        -- Dates
        effective_date,
        termination_date,
        
        -- Contract information
        contract_rate,
        is_pcp,
        
        -- Status flags
        case 
            when termination_date is null 
                or termination_date > current_date 
            then true 
            else false 
        end as is_currently_active,
        
        case 
            when effective_date <= current_date 
                and (termination_date is null or termination_date > current_date)
            then true 
            else false 
        end as is_in_effect,
        
        -- Metadata
        updated_at,
        current_timestamp() as dbt_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from source
    
    where network_status_id is not null
)

select * from renamed
