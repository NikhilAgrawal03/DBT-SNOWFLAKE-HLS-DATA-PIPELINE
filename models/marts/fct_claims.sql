{{
    config(
        materialized='incremental',
        unique_key='claim_id',
        on_schema_change='fail',
        tags=['fact', 'incremental']
    )
}}

with claims_enriched as (
    select * from {{ ref('int_claims_enriched') }}
    
    {% if is_incremental() %}
    -- Only process new/updated claims since last run
    where loaded_at > (select max(loaded_at) from {{ this }})
       or loaded_at >= dateadd(day, -{{ var('claims_lookback_days', 3) }}, current_date)
    {% endif %}
),

member_dim as (
    select member_key, member_id from {{ ref('dim_member') }}
),

provider_dim as (
    select provider_key, provider_id from {{ ref('dim_provider') }}
),

fct_claims as (
    select
        -- Fact table key
        c.claim_id,
        
        -- Foreign keys to dimensions
        m.member_key,
        p.provider_key,
        
        -- Degenerate dimensions (attributes that don't belong in dims)
        c.claim_type,
        c.diagnosis_code,
        c.procedure_code,
        c.claim_status,
        
        -- Date foreign keys (for date dimension if created)
        c.service_date,
        c.submitted_date,
        date_trunc('month', c.service_date) as service_month,
        date_trunc('year', c.service_date) as service_year,
        
        -- Facts (measures)
        c.billed_amount,
        c.allowed_amount,
        c.paid_amount,
        c.network_discount,
        c.member_responsibility,
        c.paid_percentage,
        
        -- Derived metrics
        case when c.claim_status = 'Paid' then c.paid_amount else 0 end as paid_amount_if_paid,
        case when c.claim_status = 'Denied' then 1 else 0 end as is_denied,
        case when c.claim_status = 'Paid' then 1 else 0 end as is_paid,
        
        -- Timing metrics
        c.days_to_submit,
        
        -- Flags
        c.is_late_arrival,
        c.is_orphan_member,
        c.is_orphan_provider,
        
        -- For incremental processing
        c.loaded_at,
        
        -- Metadata
        current_timestamp() as fact_created_at,
        '{{ invocation_id }}' as dbt_invocation_id

    from claims_enriched c
    left join member_dim m on c.member_id = m.member_id
    left join provider_dim p on c.provider_id = p.provider_id
    
    -- Data quality: exclude orphan records
    where c.is_orphan_member = false
      and c.is_orphan_provider = false
)

select * from fct_claims
