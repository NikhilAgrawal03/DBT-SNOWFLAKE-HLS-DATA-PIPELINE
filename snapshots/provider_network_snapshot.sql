{% snapshot provider_network_snapshot %}

{{
    config(
      target_schema='ANALYTICS_HEALTHCARE',
      unique_key='network_status_id',
      strategy='timestamp',
      updated_at='updated_at',
      invalidate_hard_deletes=True,
      tags=['snapshot', 'scd_type_2']
    )
}}

select
    network_status_id,
    provider_id,
    network_id,
    network_status,
    effective_date,
    termination_date,
    contract_rate,
    is_pcp,
    updated_at
from {{ source('raw', 'provider_network_status') }}

{% endsnapshot %}
