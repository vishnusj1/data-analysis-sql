WITH RevenueByYear AS (
    SELECT 
        EXTRACT(YEAR FROM s.order_date) AS year,
        ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue
    FROM staging_sales s
    JOIN staging_products p 
        ON s.productkey = p.productkey
    JOIN staging_exchange_rates er 
        ON s.currency_code = er.currency AND s.order_date = er.date
    GROUP BY EXTRACT(YEAR FROM s.order_date)
)

SELECT 
    year,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year) AS previous_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY year)) / 
        NULLIF(LAG(total_revenue) OVER (ORDER BY year), 0) * 100, 2
    ) AS yoy_growth_percentage
FROM RevenueByYear;
