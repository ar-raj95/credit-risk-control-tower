{#- Shared quarter logic so every model labels periods the same way. -#}
{% macro quarter_label(date_col) -%}
    cast(year({{ date_col }}) as varchar) || ' Q' || cast(quarter({{ date_col }}) as varchar)
{%- endmacro %}

{% macro quarter_key(date_col) -%}
    cast(year({{ date_col }}) * 10 + quarter({{ date_col }}) as integer)
{%- endmacro %}
