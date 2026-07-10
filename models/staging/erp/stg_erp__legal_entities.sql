with source as (
    select * from {{ source('erp', 'raw_legal_entities') }}
),

cleaned as (
    select
        trim(entity_code)               as entity_id,
        trim(entity_code)               as entity_code,
        trim(entity_name)               as entity_name,
        trim(entity_country)            as entity_country,
        upper(trim(entity_currency))    as entity_currency,
        is_intercompany,
        trim(consolidation_group)       as consolidation_group
    from source
)

select * from cleaned
