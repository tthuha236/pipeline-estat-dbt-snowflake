WITH stg_table AS (
    SELECT * FROM estat_db.estat_stg.dim_expense_catalog_stg
     WHERE loaded_time = (
        SELECT max(loaded_time) from estat_db.estat_stg.dim_expense_catalog_stg 
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