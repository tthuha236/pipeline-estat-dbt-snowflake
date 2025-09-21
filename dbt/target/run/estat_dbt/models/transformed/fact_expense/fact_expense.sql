begin;
    
        delete from estat_db.estat_transformed.fact_expense as DBT_INTERNAL_DEST
        where (category_cd, area_cd, year, month) in (
            select distinct category_cd, area_cd, year, month
            from estat_db.estat_transformed.fact_expense__dbt_tmp as DBT_INTERNAL_SOURCE
        );

    

    insert into estat_db.estat_transformed.fact_expense ("CATEGORY_CD", "AMOUNT", "AREA_CD", "YEAR", "MONTH", "CREATED_AT", "UPDATED_AT", "CREATED_BY", "UPDATED_BY")
    (
        select "CATEGORY_CD", "AMOUNT", "AREA_CD", "YEAR", "MONTH", "CREATED_AT", "UPDATED_AT", "CREATED_BY", "UPDATED_BY"
        from estat_db.estat_transformed.fact_expense__dbt_tmp
    );
    commit;