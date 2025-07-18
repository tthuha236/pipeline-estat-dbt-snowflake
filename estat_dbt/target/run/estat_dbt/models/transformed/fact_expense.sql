
  
    

create or replace transient table estat_db.estat_transformed.fact_expense
    
    
    
    as (

WITH stg_table AS (
    SELECT * FROM estat_db.estat_stg.fact_expense_stg
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
    )
;


  