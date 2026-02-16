{{
    config(
        materialized='table',
        tags=['dimension']
    )
}}

with providers as (
    select * from {{ ref('stg_providers') }}
),

provider_networks as (
    select * from {{ ref('int_provider_network_current') }}
),

provider_dim as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['p.provider_id']) }} as provider_key,
        
        -- Natural key
        p.provider_id,
        p.npi,
        
        -- Provider attributes
        p.first_name,
        p.last_name,
        p.first_name || ' ' || p.last_name as provider_full_name,
        p.specialty,
        p.provider_type,
        p.organization_name,
        
        -- Location attributes
        p.address,
        p.city,
        p.state,
        p.zip_code,
        p.phone,
        
        -- Status attributes
        p.accepting_new_patients,
        
        -- Network information
        coalesce(n.network_ids, 'Not in Network') as network_ids,
        coalesce(n.is_in_any_network, 0) as is_in_network,
        n.is_pcp,
        n.highest_contract_rate,
        
        -- Specialty categorization
        case
            when p.specialty in ('Family Medicine', 'Internal Medicine', 'Pediatrics', 'General Practice') 
                then 'Primary Care'
            when p.specialty in ('Cardiology', 'Neurology', 'Oncology', 'Endocrinology', 'Gastroenterology')
                then 'Medical Specialist'
            when p.specialty in ('Orthopedics', 'General Surgery', 'Neurosurgery', 'Cardiothoracic Surgery')
                then 'Surgical Specialist'
            when p.specialty in ('Radiology', 'Pathology', 'Anesthesiology')
                then 'Diagnostic/Support'
            when p.specialty in ('Psychiatry', 'Psychology')
                then 'Behavioral Health'
            else 'Other'
        end as specialty_category,
        
        -- Metadata
        current_timestamp() as dim_created_at,
        current_timestamp() as dim_updated_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from providers p
    left join provider_networks n on p.provider_id = n.provider_id
)

select * from provider_dim
