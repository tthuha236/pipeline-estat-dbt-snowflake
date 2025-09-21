
    
    

select
    ken_name as unique_field,
    count(*) as n_records

from estat_db.estat_stg.dim_city_region_stg
where ken_name is not null
group by ken_name
having count(*) > 1


