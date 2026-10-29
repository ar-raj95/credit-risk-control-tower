-- Data quality results by rule and quarter, generated from the dq_rule_catalog seed.
-- Adding a rule is a one-line change to the seed, reviewed in a pull request.
-- Rules run on staging (before dedup and cleaning) so defects are measured, not hidden.

{%- set rules = [] -%}
{%- if execute -%}
    {%- set rules = run_query(
        "select rule_id, fail_condition from " ~ ref('dq_rule_catalog') ~ " order by rule_id"
    ).rows -%}
{%- endif %}

with base as (
    select
        l.*,
        s.state_name,
        count(*) over (partition by l.loan_id) as loan_id_occurrences,
        {{ quarter_key('l.issue_date') }} as period_key,
        {{ quarter_label('l.issue_date') }} as period
    from {{ ref('stg_lendingclub__loans') }} as l
    left join {{ ref('state_region') }} as s on l.state_code = s.state_code
),

evaluated as (
    {%- for rule_id, fail_condition in rules %}
        select
            '{{ rule_id }}' as rule_id,
            period_key,
            period,
            cast(count(*) as bigint) as records,
            cast(sum(case when coalesce({{ fail_condition }}, false) then 1 else 0 end) as bigint) as failed
        from base
        group by period_key, period
        {% if not loop.last %}union all{% endif %}
    {%- endfor %}
)

select
    e.rule_id,
    c.dimension,
    c.field,
    c.severity,
    c.description,
    c.remediation_owner,
    e.period_key,
    e.period,
    e.records,
    e.failed,
    1 - e.failed / e.records as pass_rate
from evaluated as e
inner join {{ ref('dq_rule_catalog') }} as c on e.rule_id = c.rule_id
