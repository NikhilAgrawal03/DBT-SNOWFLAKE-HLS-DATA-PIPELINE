{{
    config(
        materialized='view',
        tags=['pii']
    )
}}

with source as (
    select * from {{ source('raw', 'members') }}
),

renamed as (
    select
        -- Primary key
        member_id,
        
        -- Personal information
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        date_of_birth,
        upper(gender) as gender,
        
        -- Contact information
        trim(address) as address,
        trim(city) as city,
        upper(state) as state,
        {{ standardize_zip_code('zip_code') }} as zip_code,
        {{ standardize_phone('phone') }} as phone,
        lower(trim(email)) as email,
        
        -- Enrollment information
        enrollment_date,
        member_status,
        
        -- Calculated fields
        {{ dbt.datediff('date_of_birth', dbt.current_timestamp(), 'year') }} as current_age,
        {{ dbt.datediff('enrollment_date', dbt.current_timestamp(), 'year') }} as years_enrolled,
        
        -- Metadata
        current_timestamp() as dbt_loaded_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from source
    
    -- Data quality filters
    where member_id is not null
)

select * from renamed
