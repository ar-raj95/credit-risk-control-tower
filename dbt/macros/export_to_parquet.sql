{#-
  After a run, write every node tagged meta.export = true to Parquet for
  Power BI. All or nothing: if any node or test errored or failed, nothing is
  exported, so the report never mixes fresh and stale tables and never shows
  data that failed a gate. Warnings do not block the export.
-#}
{% macro export_to_parquet(results) %}
    {% if execute and target.type == 'duckdb' %}
        {% set failures = results | selectattr('status', 'in', ['error', 'fail']) | list %}
        {% if failures | length > 0 %}
            {{ log("Export skipped: " ~ failures | length ~ " node(s) failed. Power BI keeps the last good data.", info=true) }}
        {% else %}
            {% for res in results %}
                {% set node = res.node %}
                {% if node.resource_type in ('model', 'seed')
                      and res.status == 'success'
                      and node.config.meta.get('export') %}
                    {% set file = var('export_path') ~ '/' ~ node.name ~ '.parquet' %}
                    {% do run_query("copy (select * from " ~ node.relation_name ~ ") to '" ~ file ~ "' (format parquet)") %}
                    {{ log("Exported " ~ node.name ~ " -> " ~ file, info=true) }}
                {% endif %}
            {% endfor %}
        {% endif %}
    {% endif %}
{% endmacro %}
