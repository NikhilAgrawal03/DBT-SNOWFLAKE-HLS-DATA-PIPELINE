{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('raw', 'providers') }}
),

renamed as (
    select
        -- Primary key
        provider_id,
        
        -- National Provider Identifier
        npi,
        
        -- Provider information
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        trim(specialty) as specialty,
        trim(organization_name) as organization_name,
        
        -- Location information
        trim(address) as address,
        trim(city) as city,
        upper(state) as state,
        {{ standardize_zip_code('zip_code') }} as zip_code,
        {{ standardize_phone('phone') }} as phone,
        
        -- Provider characteristics
        provider_type,
        accepting_new_patients,
        
        -- Metadata
        current_timestamp() as dbt_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from source
    
    -- Data quality filters
    where provider_id is not null
)

select * from renamed
