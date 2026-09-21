{{ table_config('table') }}

WITH ticket_orders_raw AS (
    SELECT DISTINCT
        order_id,
        booker_id,
        product_type,
        sales_channel,
        COALESCE(ticket_count, 0) AS ticket_count,
        STRUCT(
            pricing_currency AS currency,
            pricing_average_ticket_price AS average_ticket_price,
            pricing_total_gross AS total_gross
        ) AS pricing,
        STRUCT(
            customer_country AS country,
            customer_region AS region,
            customer_city AS city,
            customer_postal_code AS postal_code
        ) AS customer,
        STRUCT(
            performance_show_name AS show_name,
            performance_starts_at AS starts_at
        ) AS performance,
        STRUCT(
            purchase_purchased_at AS purchased_at,
            purchase_lead_time_days AS lead_time_days,
            purchase_weeks_prior_to_performance AS weeks_prior_to_performance
        ) AS purchase
    FROM
        {{ source('client_1', 'ticket_orders') }}
)

-- Select everything from the final CTE and include inserted_at
SELECT 
    *,
    CURRENT_TIMESTAMP() AS inserted_at
FROM
    ticket_orders_raw
