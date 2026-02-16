{% macro standardize_zip_code(column_name) %}
    left(regexp_replace({{ column_name }}, '[^0-9]', ''), 5)
{% endmacro %}
