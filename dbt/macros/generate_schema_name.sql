{#- Use the folder schema as-is (staging, marts...) instead of prefixing the target schema. -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name | trim if custom_schema_name is not none else target.schema }}
{%- endmacro %}
