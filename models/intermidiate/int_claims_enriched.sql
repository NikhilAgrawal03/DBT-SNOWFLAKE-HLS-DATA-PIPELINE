{{
    config(
        materialized='ephemeral'
    )
}}

with claims as (
    select * from {{ ref('stg_claims') }}
),

members as (
    select * from {{ ref('stg_members') }}
),

providers as (
    select * from {{ ref('stg_providers') }}
),

enriched as (
    select
        -- Claim identifiers
        c.claim_id,
        c.member_id,
        c.provider_id,
        
        -- Claim details
        c.claim_type,
        c.service_date,
        c.submitted_date,
        c.diagnosis_code,
        c.procedure_code,
        c.claim_status,
        
        -- Financial
        c.billed_amount,
        c.allowed_amount,
        c.paid_amount,
        c.network_discount,
        c.member_responsibility,
        c.paid_percentage,
        
        -- Timing
        c.days_to_submit,
        c.is_late_arrival,
        
        -- Member attributes
        m.first_name as member_first_name,
        m.last_name as member_last_name,
        m.date_of_birth,
        m.gender,
        m.current_age,
        m.state as member_state,
        m.member_status,
        
        -- Provider attributes
        p.first_name as provider_first_name,
        p.last_name as provider_last_name,
        p.npi,
        p.specialty,
        p.organization_name,
        p.provider_type,
        p.state as provider_state,
        
        -- Data quality flags
        case when m.member_id is null then true else false end as is_orphan_member,
        case when p.provider_id is null then true else false end as is_orphan_provider,
        
        -- Metadata
        c.loaded_at,
        c.dbt_loaded_at

    from claims c
    left join members m on c.member_id = m.member_id
    left join providers p on c.provider_id = p.provider_id
)

select * from enriched
