
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select ken_name
from estat_db.estat_stg.dim_city_region_stg
where ken_name is null



  
  
      
    ) dbt_internal_test