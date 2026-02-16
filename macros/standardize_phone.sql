{% macro standardize_phone(column_name) %}
    regexp_replace(
        regexp_replace({{ column_name }}, '[^0-9]', ''),
        '^1',
        ''
    )
{% endmacro %}
