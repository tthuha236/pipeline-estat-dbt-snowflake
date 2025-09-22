
  
    

create or replace transient table estat_db.estat_mart.agg_expense_monthly_total
    
    
    
    as (WITH src AS (
  SELECT ken_name,
        chihou,
        year,
        month,
        SUM(src.amount) AS total_amount
  FROM estat_db.estat_mart.agg_expense_by_main_category src
    
  GROUP BY 1,2,3,4
)
SELECT 
  src.*,
  COALESCE(t.created_at, CURRENT_TIMESTAMP()) AS created_at,
  CURRENT_TIMESTAMP() AS updated_at,
  COALESCE(t.created_by, CURRENT_USER()) AS created_by,
  CURRENT_USER() AS updated_by
FROM src
LEFT JOIN estat_db.estat_mart.agg_expense_monthly_total t
 ON src.ken_name = t.ken_name
 AND src.year = t.year
 AND src.month = t.month
    )
;


  