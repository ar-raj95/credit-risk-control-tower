{#-
  Bin-level population stability for one feature.

  Bins are deciles of the baseline population (var psi_baseline_years). Each
  later quarter is compared against that fixed baseline. Shares are floored
  at 0.0001 so empty bins do not produce log(0).
  Returns: feature, period_key, period, bin_no, baseline_share, current_share, psi_contribution
-#}
{% macro psi_bins(relation, feature) %}
    {%- set n = var('psi_bins') -%}
    {%- set probs = [] -%}
    {%- for i in range(1, n) %}{% do probs.append((i / n) | round(4)) %}{% endfor -%}
    {%- set baseline = var('psi_baseline_years') | join(', ') -%}

    (
    with population as (
        select loan_id, issue_year, issue_quarter_key, issue_quarter,
               cast({{ feature }} as double) as value
        from {{ relation }}
        where {{ feature }} is not null
    ),
    edges as (
        -- Distinct baseline decile cut points (discrete features can repeat cuts).
        select distinct unnest(cuts) as edge
        from (
            select quantile_cont(value, [{{ probs | join(', ') }}]) as cuts
            from population
            where issue_year in ({{ baseline }})
        )
    ),
    binned as (
        select p.loan_id, p.issue_year, p.issue_quarter_key, p.issue_quarter,
               count(e.edge) as bin_no
        from population as p
        left join edges as e on p.value >= e.edge
        group by p.loan_id, p.issue_year, p.issue_quarter_key, p.issue_quarter
    ),
    bins as (
        select unnest(range(0, (select count(*) from edges) + 1)) as bin_no
    ),
    baseline_dist as (
        select bin_no, count(*) / sum(count(*)) over () as share
        from binned where issue_year in ({{ baseline }})
        group by bin_no
    ),
    current_dist as (
        select issue_quarter_key, issue_quarter, bin_no,
               count(*) / sum(count(*)) over (partition by issue_quarter_key) as share
        from binned where issue_year > {{ var('psi_baseline_years') | max }}
        group by issue_quarter_key, issue_quarter, bin_no
    ),
    periods as (select distinct issue_quarter_key, issue_quarter from current_dist),
    grid as (
        select p.issue_quarter_key, p.issue_quarter, b.bin_no,
               greatest(coalesce(bd.share, 0), 0.0001) as baseline_share,
               greatest(coalesce(cd.share, 0), 0.0001) as current_share
        from periods as p
        cross join bins as b
        left join baseline_dist as bd on b.bin_no = bd.bin_no
        left join current_dist as cd
            on cd.issue_quarter_key = p.issue_quarter_key and cd.bin_no = b.bin_no
    )
    select
        '{{ feature }}'                                       as feature,
        issue_quarter_key                                     as period_key,
        issue_quarter                                         as period,
        bin_no,
        baseline_share,
        current_share,
        (current_share - baseline_share) * ln(current_share / baseline_share) as psi_contribution
    from grid
    )
{% endmacro %}
