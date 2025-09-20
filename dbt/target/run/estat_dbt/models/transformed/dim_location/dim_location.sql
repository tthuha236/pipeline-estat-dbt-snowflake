
  
    

create or replace transient table estat_db.estat_transformed.dim_location
    
    
    
    as (WITH city AS (
    SELECT * FROM estat_db.estat_stg.dim_city_stg 
),
region AS (
    SELECT * FROM estat_db.estat_stg.dim_city_region_stg
)
SELECT 
    c.KEN_CODE,
    c.SITYOUSON_CODE,
    c.TIIKI_CODE,
    c.KEN_NAME,
    c.SITYOUSON_NAME1,
    c.SITYOUSON_NAME2,
    c.SITYOUSON_NAME3,
    c.YOMIGANA,
    r.CHIHOU,
    CURRENT_TIMESTAMP() AS CREATED_TIME
FROM city c
JOIN region r
  ON c.KEN_NAME = r.KEN_NAME
    )
;


  