{{ table_config('table') }}

-- Select desired columns from the warehouse model
-- It is possible that product_type can be included here, but that would be assuming a 1:1 relationship between it and show_name
WITH warehouse_model AS (
    SELECT DISTINCT
        performance.show_name AS show_name,
        performance.starts_at AS starts_at
    FROM
        {{ ref('ticket_orders') }}
),

-- Add unique surrogate keys
add_keys AS (
    SELECT 
        {{ generate_key(['show_name', 'starts_at']) }} AS performance_unique_id,
        *
    FROM
        warehouse_model
)

-- Select everything from the final CTE
SELECT *
FROM
    add_keys
