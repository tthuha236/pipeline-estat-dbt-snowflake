
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    tiiki_code as unique_field,
    count(*) as n_records

from estat_db.estat_stg.dim_city_stg
where tiiki_code is not null
group by tiiki_code
having count(*) > 1



  
  
      
    ) dbt_internal_test