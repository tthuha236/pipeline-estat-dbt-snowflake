WITH stg_table AS (
    SELECT * FROM ESTAT_DB.ESTAT_STG.fact_expense_stg
)
SELECT 
    CATEGORY_CD,
    AMOUNT, 
    AREA_CD, 
    YEAR,
    MONTH,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at
FROM stg_table