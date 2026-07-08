{% snapshot snap_chart_of_accounts %}
{{
    config(
        target_schema='finance_snapshots',
        unique_key='account_number',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}
select * from {{ source('erp', 'raw_chart_of_accounts') }}
{% endsnapshot %}
