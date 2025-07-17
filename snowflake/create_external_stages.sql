USE ROLE ACCOUNTADMIN;

-- define s3 intergation to connect to s3 bucket
CREATE STORAGE INTEGRATION s3_estat_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::202093616617:role/s3-estat-data-acess-role'
  STORAGE_ALLOWED_LOCATIONS = ('*')
;

-- retrieve iam user for snowflake account
DESC INTEGRATION s3_estat_int;

-- -> record iam user arn and external id, to grant snowflake's iam user to access bucket

-- grant permission to dev role to create external stage using the s3 integration
GRANT CREATE STAGE ON SCHEMA ESTAT_DB.ESTAT_STG TO ROLE DEV;
GRANT USAGE ON INTEGRATION s3_estat_int TO ROLE DEV;

-- create external stage to test
USE SCHEMA ESTAT_DB.ESTAT_STG;

CREATE OR REPLACE STAGE s3_estat_stage
  STORAGE_INTEGRATION = s3_estat_int
  URL = 's3://estat-dbt-sf/';

-- check files in s3 stage
LIST @s3_estat_stage;

-- query a file to check
SELECT $1, $2, $3
FROM @s3_estat_stage/stg/expenses/expense_2025071622.csv;