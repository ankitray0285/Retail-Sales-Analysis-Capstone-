DROP Database Projects1;
CREATE DATABASE Retail;
USE Retail;
-- 1. Overall Return Rate
SELECT
  ROUND(
    100.0 * SUM(CASE WHEN is_returned = TRUE THEN quantity ELSE 0 END) / SUM(quantity),
    2
  ) AS return_rate_percent
FROM order_items;

-- 2. Top 10 Returned SKUs by Return Rate
WITH sku_summary AS (
  SELECT
    sku,
    SUM(quantity) AS total_sold,
    SUM(CASE WHEN is_returned = TRUE THEN quantity ELSE 0 END) AS total_returned
  FROM order_items
  GROUP BY sku
)
SELECT
  sku,
  total_sold,
  total_returned,
  ROUND(100.0 * total_returned / total_sold, 2) AS return_rate_percent
FROM sku_summary
ORDER BY return_rate_percent DESC
LIMIT 10;

-- 3. Return-Adjusted Net Profit per SKU
WITH item_details AS (
  SELECT
    oi.sku,
    oi.quantity,
    oi.price,
    p.cost_price,
    oi.is_returned
  FROM order_items oi
  JOIN products p ON oi.sku = p.sku
),
sku_profit AS (
  SELECT
    sku,
    SUM(CASE WHEN is_returned = FALSE THEN (price - cost_price) * quantity ELSE 0 END) AS gross_profit,
    SUM(CASE WHEN is_returned = TRUE THEN (price - cost_price) * quantity ELSE 0 END) AS return_loss
  FROM item_details
  GROUP BY sku
)
SELECT
  sku,
  gross_profit,
  return_loss,
  (gross_profit - return_loss) AS net_profit
FROM sku_profit
ORDER BY net_profit ASC;

-- 4. Region-Wise Return Rate & Net Profit
WITH full_data AS (
  SELECT
    c.region,
    oi.sku,
    oi.quantity,
    oi.price,
    oi.is_returned,
    p.cost_price
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  JOIN customers c ON o.customer_id = c.customer_id
  JOIN products p ON oi.sku = p.sku
),
region_summary AS (
  SELECT
    region,
    SUM(quantity) AS total_qty,
    SUM(CASE WHEN is_returned THEN quantity ELSE 0 END) AS returned_qty,
    SUM(CASE WHEN NOT is_returned THEN (price - cost_price) * quantity ELSE 0 END) AS gross_profit,
    SUM(CASE WHEN is_returned THEN (price - cost_price) * quantity ELSE 0 END) AS return_loss
  FROM full_data
  GROUP BY region
)
SELECT
  region,
  ROUND(100.0 * returned_qty / total_qty, 2) AS return_rate_percent,
  gross_profit,
  return_loss,
  (gross_profit - return_loss) AS net_profit
FROM region_summary
ORDER BY net_profit;

-- 5. Return Rate by Product Category
WITH item_cat AS (
  SELECT
    oi.sku,
    p.category,
    oi.quantity,
    oi.is_returned
  FROM order_items oi
  JOIN products p ON oi.sku = p.sku
)
SELECT
  category,
  SUM(quantity) AS total_qty,
  SUM(CASE WHEN is_returned THEN quantity ELSE 0 END) AS returned_qty,
  ROUND(100.0 * SUM(CASE WHEN is_returned THEN quantity ELSE 0 END) / SUM(quantity), 2) AS return_rate_percent
FROM item_cat
GROUP BY category
ORDER BY return_rate_percent DESC;

-- 6. Return Rate Trend Over Time (Monthly)
WITH return_trend AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    oi.quantity,
    oi.is_returned
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
)
SELECT
  month,
  SUM(quantity) AS total_items,
  SUM(CASE WHEN is_returned THEN quantity ELSE 0 END) AS returned_items,
  ROUND(100.0 * SUM(CASE WHEN is_returned THEN quantity ELSE 0 END) / SUM(quantity), 2) AS return_rate_percent
FROM return_trend
GROUP BY month
ORDER BY month;
