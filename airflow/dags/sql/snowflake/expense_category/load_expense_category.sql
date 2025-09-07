COPY INTO {{ params.db }}.{{ params.stg_schema }}.{{ params.stg_table }}
  FROM
  (
    SELECT $1, $2, $3, $4, $5,
               METADATA$FILE_LAST_MODIFIED,
               CURRENT_USER(),
               METADATA$FILENAME
        FROM @{{ params.s3_stage }}/{output_file}
   )
    FILE_FORMAT = (TYPE='CSV' SKIP_HEADER=1)
;