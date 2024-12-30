WITH RevenueProfitCTE AS (
    SELECT 
        s.order_number,
        EXTRACT(YEAR FROM s.order_date) AS year,
        EXTRACT(MONTH FROM s.order_date) AS month,
        ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue,
        ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS total_profit
    FROM staging_sales s
    JOIN staging_products p 
        ON s.productkey = p.productkey
    JOIN staging_exchange_rates er 
        ON s.currency_code = er.currency AND s.order_date = er.date
    GROUP BY s.order_number, EXTRACT(YEAR FROM s.order_date), EXTRACT(MONTH FROM s.order_date)
)

SELECT 
    year,
    month,
    SUM(total_revenue) AS monthly_revenue,
    SUM(total_profit) AS monthly_profit
FROM RevenueProfitCTE
GROUP BY year, month
ORDER BY year, month;