{% test claim_amounts_are_valid(model, column_name) %}

-- Test that billed >= allowed >= paid for claims
-- This is a business rule for healthcare claims

with validation as (
    select
        {{ column_name }} as claim_id,
        billed_amount,
        allowed_amount,
        paid_amount
    from {{ model }}
    where claim_status = 'Paid'
)

select *
from validation
where billed_amount < allowed_amount
   or allowed_amount < paid_amount
   or billed_amount < 0
   or allowed_amount < 0
   or paid_amount < 0

{% endtest %}
