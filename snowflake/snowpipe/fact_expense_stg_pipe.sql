CREATE PIPE fact_expense_stg_pipe
  AUTO_INGEST = TRUE
  AS
    COPY INTO fact_expense_stg
  FROM
  (
    SELECT $1, $2, $3, $4, $5,
               METADATA$FILE_LAST_MODIFIED,
               CURRENT_USER(),
               METADATA$FILENAME
        FROM @s3_estat_stage/stg/expenses/
   )
    PATTERN = '[expense_].*[.]csv'
    FILE_FORMAT = (TYPE='CSV' SKIP_HEADER=1)
;
