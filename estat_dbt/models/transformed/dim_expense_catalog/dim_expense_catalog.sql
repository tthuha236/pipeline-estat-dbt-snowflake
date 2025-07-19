WITH stg_table AS (
    SELECT * FROM {{ source('dim_expense_catalog_stg', 'input_table') }}
     WHERE loaded_time = (
        SELECT max(loaded_time) from {{ source('dim_expense_catalog_stg', 'input_table')}} 
    )
) 
SELECT 
    CATEGORY_CD,
    CATEGORY_NAME,
    MAJOR_CATEGORY_CD,
    MEDIUM_CATEGORY_CD,
    MAJOR_CATEGORY_NAME,
    MEDIUM_CATEGORY_NAME 
FROM 
    stg_table
