-- Singular test: Check for potential duplicate members based on name and DOB
-- These could indicate data quality issues in source systems

with member_duplicates as (
    select
        first_name,
        last_name,
        date_of_birth,
        count(*) as duplicate_count
    from {{ ref('stg_members') }}
    group by 1, 2, 3
    having count(*) > 1
)

select *
from member_duplicates
