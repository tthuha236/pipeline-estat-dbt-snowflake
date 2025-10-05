WITH stg_table AS (
    SELECT * FROM estat_db.estat_stg.dim_expense_category_stg
     WHERE loaded_time = (
        SELECT max(loaded_time) from estat_db.estat_stg.dim_expense_category_stg 
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