WITH stg_table AS (
    SELECT * FROM {{ source('stg', 'fact_expense_stg')}}
)
SELECT 
    s.category_cd,
    s.amount, 
    s.area_cd, 
    s.year,
    s.month,
    COALESCE(t.created_at, CURRENT_TIMESTAMP()) as created_at,
    CURRENT_TIMESTAMP() as updated_at
FROM stg_table s
LEFT JOIN {{ this }} t
ON s.category_cd = t.category_cd
  AND s.area_cd = t.area_cd
  AND s.year = t.year
  AND s.month = t.month

{% if is_incremental() %}
WHERE t.category_cd is null or s.loaded_time > t.updated_at
{% endif %}
