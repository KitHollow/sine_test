{{ table_config('view') }}

WITH ticket_orders AS (
    SELECT DISTINCT
        booker_id,
        total_gross_allocated
    FROM
        {{ ref('fact_ticket_orders') }}
    WHERE 
        EXISTS (
            SELECT 
                1 
            FROM 
                UNNEST(a.product_types) b 
            WHERE 
                b = 'Dinner & Show' -- can have this parameterised to allow for changes
        )
),

dim_bookers AS (
    SELECT 
        booker_id,
        region
    FROM
        {{ ref('dim_booker') }}
),

das_min_bookers AS (
    SELECT 
        a.*
    FROM
        ticket_orders a
    INNER JOIN
        dim_bookers b
        USING(booker_id)
    WHERE
        b.region = 'Minnesota'
),

booker_aggregation AS (
    SELECT
        booker_id,
        SUM(total_gross_allocated) AS lifetime_value
    FROM
        das_min_bookers
    GROUP BY ALL
)

SELECT *
FROM 
    booker_aggregation a
ORDER BY 
    lifetime_value DESC
LIMIT 50
