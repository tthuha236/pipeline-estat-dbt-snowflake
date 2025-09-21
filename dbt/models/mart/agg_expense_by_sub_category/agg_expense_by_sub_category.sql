WITH agg_expense as (
    SELECT
        loc.ken_name,
        loc.chihou,
        f.year,
        f.month,
        c.main_category_name,
        c.sub_category_name,
        AVG(f.amount) AS amount,
    FROM {{ ref('fact_expense') }} AS f
    JOIN {{ ref('dim_location') }} AS loc
        ON f.area_cd = loc.tiiki_code
    JOIN {{ ref('dim_expense_category') }} c
        ON f.category_cd = c.category_cd AND c.sub_category_name is not null AND c.detailed_category_name is null
    {% if is_incremental() %}
        -- only get new or updated data
        WHERE f.updated_at >= COALESCE((SELECT MAX(updated_at) from {{ this }}), '1900-01-01')
    {% endif %}
    GROUP BY 1,2,3,4,5,6
)
SELECT a.*,
    COALESCE(t.created_at, CURRENT_TIMESTAMP()) AS created_at,
    CURRENT_TIMESTAMP() as updated_at,
    COALESCE(t.created_by, CURRENT_USER()) AS created_by,
    CURRENT_USER() as updated_by
FROM agg_expense a 
LEFT JOIN {{ this }} t 
ON a.ken_name = t.ken_name
 AND a.year = t.year
 AND a.month = t.month
 AND a.sub_category_name = t.sub_category_name