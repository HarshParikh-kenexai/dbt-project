with source as (
    select * from {{ source('erp', 'raw_cost_centers') }}
),

cleaned as (
    select
        trim(cost_center_code)      as cost_center_id,
        trim(cost_center_code)      as cost_center_code,
        trim(cost_center_name)      as cost_center_name,
        trim(department)            as department,
        trim(division)              as division,
        trim(business_unit)         as business_unit,
        trim(cost_center_owner)     as cost_center_owner
    from source
    where is_active = true
)

select * from cleaned
