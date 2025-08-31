-- back compat for old kwarg name
  
  begin;
    
        
            
                
                
            
                
                
            
                
                
            
                
                
            
        
    

    

    merge into estat_db.estat_transformed.fact_expense as DBT_INTERNAL_DEST
        using estat_db.estat_transformed.fact_expense__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.category_cd = DBT_INTERNAL_DEST.category_cd
                ) and (
                    DBT_INTERNAL_SOURCE.area_cd = DBT_INTERNAL_DEST.area_cd
                ) and (
                    DBT_INTERNAL_SOURCE.year = DBT_INTERNAL_DEST.year
                ) and (
                    DBT_INTERNAL_SOURCE.month = DBT_INTERNAL_DEST.month
                )

    
    when matched then update set
        "CATEGORY_CD" = DBT_INTERNAL_SOURCE."CATEGORY_CD","AMOUNT" = DBT_INTERNAL_SOURCE."AMOUNT","AREA_CD" = DBT_INTERNAL_SOURCE."AREA_CD","YEAR" = DBT_INTERNAL_SOURCE."YEAR","MONTH" = DBT_INTERNAL_SOURCE."MONTH","CREATED_AT" = DBT_INTERNAL_SOURCE."CREATED_AT","UPDATED_AT" = DBT_INTERNAL_SOURCE."UPDATED_AT"
    

    when not matched then insert
        ("CATEGORY_CD", "AMOUNT", "AREA_CD", "YEAR", "MONTH", "CREATED_AT", "UPDATED_AT")
    values
        ("CATEGORY_CD", "AMOUNT", "AREA_CD", "YEAR", "MONTH", "CREATED_AT", "UPDATED_AT")

;
    commit;