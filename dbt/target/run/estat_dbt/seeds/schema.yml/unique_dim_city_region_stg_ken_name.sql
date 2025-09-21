
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    ken_name as unique_field,
    count(*) as n_records

from estat_db.estat_stg.dim_city_region_stg
where ken_name is not null
group by ken_name
having count(*) > 1



  
  
      
    ) dbt_internal_test