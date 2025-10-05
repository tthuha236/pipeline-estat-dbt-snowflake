WITH stg_table AS (
    SELECT * FROM estat_db.estat_stg.fact_expense_stg 
    
    WHERE loaded_time = (
        SELECT max(loaded_time) from estat_db.estat_stg.fact_expense_stg 
    )
    
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