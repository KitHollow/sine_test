{{ table_config('table') }}

WITH warehouse_model AS (
    SELECT
        order_id,
        booker_id,
        -- dim_product, and possible a sales channel dimension, could be developed to further normalise
        product_type,
        sales_channel,
        ticket_count,
        pricing.currency AS currency,
        pricing.average_ticket_price AS average_ticket_price,
        pricing.total_gross AS total_gross,
        -- performance_unique_id could replace show_name
        performance.show_name AS show_name,
        purchase.purchased_at AS purchased_at
    FROM
        {{ ref('ticket_orders') }}
),

order_aggregation AS (
    SELECT
        order_id,
        MIN(booker_id) AS booker_id,
        MIN(purchased_at) AS purchased_at,
        COUNT(*) AS line_count,
        SUM(ticket_count) AS total_tickets,
        SUM(COALESCE(total_gross, 0)) AS total_gross_sum,
        MAX(total_gross) AS total_gross_max,
        COUNT(DISTINCT total_gross) AS distinct_total_gross_count,
        ARRAY_AGG(DISTINCT product_type) AS product_types,
        ARRAY_AGG(DISTINCT sales_channel) AS sales_channels,
        ARRAY_AGG(DISTINCT show_name) AS shows
    FROM 
        warehouse_model
    GROUP BY 
        order_id
),

order_consolidation AS (
    SELECT
        *,
        CASE
            WHEN total_gross_max IS NULL AND total_gross_sum = 0 THEN 'missing_gross'
            WHEN distinct_total_gross_count = 1 AND line_count > 1 THEN 'order_level_repeated'
            WHEN sum_row_gross > max_row_gross * 1.01 AND line_count > 1 THEN 'line_level'
            WHEN line_count = 1 THEN 'single_line'
            ELSE 'allocated_proportional'
        END AS order_allocation,
        CASE
            WHEN distinct_row_gross_count = 1 AND line_count > 1 THEN total_gross_max
            WHEN total_gross_sum > total_gross_max * 1.01 AND line_count > 1 THEN total_gross_sum
            WHEN line_count = 1 THEN total_gross_sum
            ELSE max_row_gross
        END AS total_gross_allocated
    FROM 
        order_agg
),

-- Add unique surrogate keys
add_keys AS (
    SELECT
        {{ generate_key(['order_id', 'booker_id', 'purchased_at']) }} AS ticket_order_unique_id,
        *
    FROM
        order_consolidation
)

-- Select everything from the final CTE and include inserted_at
SELECT 
    *,
    CURRENT_TIMESTAMP() AS inserted_at
FROM
    add_keys
