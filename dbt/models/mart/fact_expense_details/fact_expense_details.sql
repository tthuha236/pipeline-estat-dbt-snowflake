{{ config(
    materialized='incremental',
    unique_key='year_month_area_category',
    incremental_strategy='merge'
) }}

WITH base AS (
    SELECT
        f.year,
        f.month,
        loc.ken_name,
        f.category_cd,
        item.main_category_name,
        item.sub_category_name,
        item.detailed_category_name,
        AVG(f.amount) AS avg_amount
    FROM {{ ref('fact_expense') }} AS f
    LEFT JOIN {{ ref('dim_expense_category') }} AS item
        ON f.category_cd = item.category_cd
    LEFT JOIN {{ ref('dim_location') }} AS loc
        ON f.area_cd = loc.tiiki_code
    {% if is_incremental() %}
      -- only get new or updated data
      WHERE f.updated_at >= (SELECT MAX(updated_at) FROM {{ this }})
    {% endif %}
    GROUP BY
        f.year,
        f.month,
        loc.ken_name,
        f.category_cd,
        item.main_category_name,
        item.sub_category_name,
        item.detailed_category_name
)
SELECT
    *,
    {{ dbt_utils.surrogate_key([
        'year','month','ken_name','category_cd'
    ]) }} AS surrogate_key,
    CURRENT_TIMESTAMP() as updated_at,
    CASE
        WHEN {{ is_incremental() }} THEN NULL
        ELSE CURRENT_TIMESTAMP()
    END AS created_at
FROM base;