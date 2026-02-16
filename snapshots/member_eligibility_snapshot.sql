{% snapshot member_eligibility_snapshot %}

{{
    config(
      target_schema='ANALYTICS_HEALTHCARE',
      unique_key='eligibility_id',
      strategy='timestamp',
      updated_at='updated_at',
      invalidate_hard_deletes=True,
      tags=['snapshot', 'scd_type_2']
    )
}}

select
    eligibility_id,
    member_id,
    plan_id,
    coverage_start_date,
    coverage_end_date,
    premium_amount,
    deductible_amount,
    copay_amount,
    is_active,
    updated_at
from {{ source('raw', 'member_eligibility') }}

{% endsnapshot %}
