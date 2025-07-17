CREATE PIPE dim_expense_catalog_stg_pipe
  AUTO_INGEST = TRUE
  AS
    COPY INTO dim_expense_catalog_stg
  FROM
  (
    SELECT $1, $2, $3, $4, $5, $6,
               CURRENT_TIMESTAMP(),
               CURRENT_USER(),
               METADATA$FILENAME
        FROM @s3_estat_stage/stg/expenses_catalog/
   )
    PATTERN = '[expense_catalog_].*[.]csv'
    FILE_FORMAT = (TYPE='CSV' SKIP_HEADER=1)
;
