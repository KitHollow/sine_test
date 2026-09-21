{{ table_config('table') }}

/*
    This model is built assuming that bookers do not change location
    It is possible to add more complex logic to determine an historical overview of customers locations
    This would be an SCD-2 dimension table
    This would impact downstream logic (good thing to bring up in the interview)
    This model could be split even further or enhanced with location data from another source based off postal_code
*/

-- Select desired columns from the warehouse model
-- Distinct rows are taken to produce 1 row per booker_id
-- This is assuming bookers do not change location
WITH warehouse_model AS (
    SELECT DISTINCT
        booker_id,
        customer.country AS country,
        customer.region AS region,
        customer.city AS city,
        customer.postal_code AS postal_code
    FROM
        {{ ref('ticket_orders') }}
),

-- Add unique surrogate keys
-- This would be more useful in an SCD-2 model
add_keys AS (
    SELECT 
        {{ generate_key(['booker_id' /*, postal_code*/]) }} AS booker_unique_id,
        *
    FROM
        warehouse_model
)

-- Select everything from the final CTE
SELECT *
FROM
    warehouse_model
