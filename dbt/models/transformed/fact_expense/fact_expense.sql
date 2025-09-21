WITH stg_table AS (
    SELECT * FROM {{ source('fact_expense_stg', 'input_table')}} 
    {% if is_incremental() %}
    WHERE loaded_time = (
        SELECT max(loaded_time) from {{ source('fact_expense_stg', 'input_table')}} 
    )
    {% endif %}
)
SELECT 
    s.category_cd,
    s.amount, 
    s.area_cd, 
    s.year,
    s.month,
    COALESCE(t.created_at, CURRENT_TIMESTAMP()) as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    COALESCE(t.created_by, CURRENT_USER()) as created_by,
    CURRENT_USER() as updated_by
FROM stg_table s
