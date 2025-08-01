USE SCHEMA ESTAT_DB.ESTAT_STG;

CREATE TABLE IF NOT EXISTS fact_expense_stg (
    CATEGORY_CD VARCHAR(8),
    AMOUNT DECIMAL, 
    AREA_CD VARCHAR(5), 
    YEAR INT,
    MONTH INT,
    LOADED_TIME TIMESTAMP,
    LOADED_USER VARCHAR,
    FILENAME VARCHAR
);
