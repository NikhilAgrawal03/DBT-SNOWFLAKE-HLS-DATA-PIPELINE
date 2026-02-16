-- Singular test: Ensure all member_keys in fct_claims exist in dim_member
-- This validates referential integrity of the dimensional model

with fact_members as (
    select distinct member_key
    from {{ ref('fct_claims') }}
),

dim_members as (
    select distinct member_key
    from {{ ref('dim_member') }}
)

select
    f.member_key,
    'Fact table has member_key not in dimension' as error_message
from fact_members f
left join dim_members d on f.member_key = d.member_key
where d.member_key is null
