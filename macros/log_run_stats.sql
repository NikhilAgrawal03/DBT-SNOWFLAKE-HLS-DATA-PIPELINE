{% macro log_run_stats() %}
    {% if execute %}
        {% set results_list = results | selectattr('status', 'defined') | list %}
        {% set total = results_list | length %}
        {% set success = results_list | selectattr('status', 'equalto', 'success') | list | length %}
        {% set error = results_list | selectattr('status', 'equalto', 'error') | list | length %}
        {% set skipped = results_list | selectattr('status', 'equalto', 'skipped') | list | length %}
        
        {{ log('', info=True) }}
        {{ log('Run Statistics:', info=True) }}
        {{ log('  Total models: ' ~ total, info=True) }}
        {{ log('  Success: ' ~ success, info=True) }}
        {{ log('  Error: ' ~ error, info=True) }}
        {{ log('  Skipped: ' ~ skipped, info=True) }}
        
        {% if error > 0 %}
            {{ log('', info=True) }}
            {{ log('Failed models:', info=True) }}
            {% for result in results_list %}
                {% if result.status == 'error' %}
                    {{ log('  - ' ~ result.node.name, info=True) }}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endif %}
{% endmacro %}
