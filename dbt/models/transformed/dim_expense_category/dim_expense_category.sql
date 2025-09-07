WITH stg_table AS (
    SELECT * FROM {{ source('dim_expense_category_stg', 'input_table') }}
     WHERE loaded_time = (
        SELECT max(loaded_time) from {{ source('dim_expense_category_stg', 'input_table')}} 
    )
) 
SELECT 
    CATEGORY_CD,
    MAIN_CATEGORY_NAME,
    SUB_CATEGORY_NAME,
    DETAILED_CATEGORY_NAME,
    DESCRIPTION
FROM 
    stg_table
