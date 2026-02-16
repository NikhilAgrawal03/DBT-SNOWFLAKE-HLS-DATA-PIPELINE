{{
    config(
        materialized='ephemeral'
    )
}}

with network_status as (
    select * from {{ ref('stg_provider_network_status') }}
),

-- Get current network status per provider per network
current_status as (
    select
        *,
        row_number() over (
            partition by provider_id, network_id 
            order by effective_date desc, updated_at desc
        ) as recency_rank
    from network_status
    where is_in_effect = true
),

-- Aggregate to provider level (may be in multiple networks)
provider_networks as (
    select
        provider_id,
        listagg(distinct network_id, ', ') within group (order by network_id) as network_ids,
        max(case when network_status = 'In-Network' then 1 else 0 end) as is_in_any_network,
        min(effective_date) as earliest_network_date,
        max(contract_rate) as highest_contract_rate,
        max(case when is_pcp = true then 1 else 0 end) as is_pcp
    from current_status
    where recency_rank = 1
    group by provider_id
),

final as (
    select
        provider_id,
        network_ids,
        is_in_any_network,
        earliest_network_date,
        highest_contract_rate,
        case when is_pcp = 1 then true else false end as is_pcp,
        current_timestamp() as dbt_loaded_at
    from provider_networks
)

select * from final
