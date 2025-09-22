-- back compat for old kwarg name
  
  begin;
    
        
            
                
                
            
                
                
            
                
                
            
                
                
            
        
    

    

    merge into estat_db.estat_mart.agg_expense_by_main_category as DBT_INTERNAL_DEST
        using estat_db.estat_mart.agg_expense_by_main_category__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.ken_name = DBT_INTERNAL_DEST.ken_name
                ) and (
                    DBT_INTERNAL_SOURCE.year = DBT_INTERNAL_DEST.year
                ) and (
                    DBT_INTERNAL_SOURCE.month = DBT_INTERNAL_DEST.month
                ) and (
                    DBT_INTERNAL_SOURCE.main_category_name = DBT_INTERNAL_DEST.main_category_name
                )

    
    when matched then update set
        "KEN_NAME" = DBT_INTERNAL_SOURCE."KEN_NAME","CHIHOU" = DBT_INTERNAL_SOURCE."CHIHOU","YEAR" = DBT_INTERNAL_SOURCE."YEAR","MONTH" = DBT_INTERNAL_SOURCE."MONTH","MAIN_CATEGORY_NAME" = DBT_INTERNAL_SOURCE."MAIN_CATEGORY_NAME","AMOUNT" = DBT_INTERNAL_SOURCE."AMOUNT","CREATED_AT" = DBT_INTERNAL_SOURCE."CREATED_AT","UPDATED_AT" = DBT_INTERNAL_SOURCE."UPDATED_AT","CREATED_BY" = DBT_INTERNAL_SOURCE."CREATED_BY","UPDATED_BY" = DBT_INTERNAL_SOURCE."UPDATED_BY"
    

    when not matched then insert
        ("KEN_NAME", "CHIHOU", "YEAR", "MONTH", "MAIN_CATEGORY_NAME", "AMOUNT", "CREATED_AT", "UPDATED_AT", "CREATED_BY", "UPDATED_BY")
    values
        ("KEN_NAME", "CHIHOU", "YEAR", "MONTH", "MAIN_CATEGORY_NAME", "AMOUNT", "CREATED_AT", "UPDATED_AT", "CREATED_BY", "UPDATED_BY")

;
    commit;