-- Bin-level PSI detail for the drill-through ("which part of the distribution moved?").

{% for feature in var('psi_features') %}
    select * from {{ psi_bins(ref('int_loans_enriched'), feature) }}
    {% if not loop.last %}union all{% endif %}
{% endfor %}
