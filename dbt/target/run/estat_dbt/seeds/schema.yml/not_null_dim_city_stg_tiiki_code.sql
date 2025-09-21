
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select tiiki_code
from estat_db.estat_stg.dim_city_stg
where tiiki_code is null



  
  
      
    ) dbt_internal_test