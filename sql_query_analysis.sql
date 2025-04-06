use bikestores;
-- Customer Purchase Behavior Analysis
-- Customer segmentation by purchase frequency and amount
WITH CustomerStats AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.city,
        c.state,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS days_since_last_order
    FROM sales.customers c
    JOIN sales.orders o ON c.customer_id = o.customer_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.state
)
SELECT 
    customer_id,
    customer_name,
    city,
    state,
    order_count,
    total_spent,
    days_since_last_order,
    CASE 
        WHEN days_since_last_order <= 30 THEN 'Active'
        WHEN days_since_last_order <= 90 THEN 'Lapsing'
        WHEN days_since_last_order <= 180 THEN 'At Risk'
        ELSE 'Lost'
    END AS customer_status,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_quartile
FROM CustomerStats
ORDER BY total_spent DESC;

-- Product performance across stores with inventory analysis
WITH ProductSales AS (
    SELECT 
        p.product_id,
        p.product_name,
        b.brand_name,
        c.category_name,
        p.list_price,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM production.products p
    JOIN production.brands b ON p.brand_id = b.brand_id
    JOIN production.categories c ON p.category_id = c.category_id
    JOIN sales.order_items oi ON p.product_id = oi.product_id
    JOIN sales.orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 4 -- Completed orders only
    GROUP BY p.product_id, p.product_name, b.brand_name, c.category_name, p.list_price
),
InventoryStatus AS (
    SELECT 
        s.product_id,
        SUM(s.quantity) AS total_inventory,
        COUNT(DISTINCT s.store_id) AS stores_with_stock
    FROM production.stocks s
    GROUP BY s.product_id
)
SELECT 
    ps.*,
    ISNULL(ist.total_inventory, 0) AS total_inventory,
    ISNULL(ist.stores_with_stock, 0) AS stores_with_stock,
    CASE 
        WHEN ISNULL(ist.total_inventory, 0) = 0 THEN 'Out of Stock'
        WHEN ISNULL(ist.total_inventory, 0) < ps.total_units_sold/12 THEN 'Low Stock'
        WHEN ISNULL(ist.total_inventory, 0) > ps.total_units_sold/3 THEN 'Overstocked'
        ELSE 'Adequate Stock'
    END AS inventory_status,
    ps.total_revenue / NULLIF(ps.order_count, 0) AS avg_order_value,
    RANK() OVER (PARTITION BY ps.category_name ORDER BY ps.total_revenue DESC) AS category_rank
FROM ProductSales ps
LEFT JOIN InventoryStatus ist ON ps.product_id = ist.product_id
ORDER BY ps.total_revenue DESC;

-- Monthly sales trends with YoY comparison and running totals
WITH MonthlySales AS (
    SELECT 
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month_start,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS monthly_sales,
        SUM(oi.quantity) AS monthly_units,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 4 -- Completed orders
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
)
SELECT 
    year,
    month,
    FORMAT(month_start, 'yyyy-MM') AS year_month,
    monthly_sales,
    monthly_units,
    order_count,
    monthly_sales / order_count AS avg_order_value,
    LAG(monthly_sales, 12) OVER (ORDER BY year, month) AS prev_year_sales,
    (monthly_sales - LAG(monthly_sales, 12) OVER (ORDER BY year, month)) / 
        NULLIF(LAG(monthly_sales, 12) OVER (ORDER BY year, month), 0) * 100 AS yoy_growth_pct,
    SUM(monthly_sales) OVER (PARTITION BY year ORDER BY month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ytd_sales,
    AVG(monthly_sales) OVER (ORDER BY year, month 
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS rolling_12mo_avg
FROM MonthlySales
ORDER BY year, month;


-- Staff performance by store with comparison to peers
WITH StaffSales AS (
    SELECT 
        s.staff_id,
        CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
        st.store_name,
        s.manager_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
        SUM(oi.quantity) AS total_units,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM sales.staffs s
    JOIN sales.orders o ON s.staff_id = o.staff_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN sales.stores st ON s.store_id = st.store_id
    WHERE o.order_status = 4 -- Completed orders
    GROUP BY s.staff_id, s.first_name, s.last_name, st.store_name, s.manager_id
),
StoreStats AS (
    SELECT 
        store_name,
        AVG(total_sales) AS avg_staff_sales,
        MAX(total_sales) AS top_staff_sales,
        SUM(total_sales) AS store_total_sales
    FROM StaffSales
    GROUP BY store_name
)
SELECT 
    ss.staff_id,
    ss.staff_name,
    ss.store_name,
    ss.order_count,
    ss.total_sales,
    ss.total_units,
    ss.total_sales / NULLIF(ss.order_count, 0) AS avg_order_value,
    st.avg_staff_sales,
    st.top_staff_sales,
    ss.total_sales / NULLIF(st.store_total_sales, 0) * 100 AS pct_of_store_sales,
    DENSE_RANK() OVER (PARTITION BY ss.store_name ORDER BY ss.total_sales DESC) AS store_rank,
    CASE 
        WHEN ss.total_sales > st.avg_staff_sales * 1.5 THEN 'Top Performer'
        WHEN ss.total_sales > st.avg_staff_sales THEN 'Above Average'
        WHEN ss.total_sales = st.avg_staff_sales THEN 'Average'
        ELSE 'Below Average'
    END AS performance_category
FROM StaffSales ss
JOIN StoreStats st ON ss.store_name = st.store_name
ORDER BY ss.store_name, ss.total_sales DESC;


-- Sales by geographic region with market penetration analysis
WITH RegionSales AS (
    SELECT 
        c.state,
        c.city,
        COUNT(DISTINCT c.customer_id) AS total_customers,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
        SUM(oi.quantity) AS total_units
    FROM sales.customers c
    LEFT JOIN sales.orders o ON c.customer_id = o.customer_id AND o.order_status = 4
    LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY c.state, c.city
),
StatePopulation AS (
    -- This would normally come from an external data source
    -- Using placeholder values for demonstration
    SELECT 'California' AS state, 39500000 AS population UNION ALL
    SELECT 'New York', 19500000 UNION ALL
    SELECT 'Texas', 29000000 UNION ALL
    SELECT 'Florida', 21500000
)
SELECT 
    rs.state,
    rs.city,
    rs.total_customers,
    rs.total_orders,
    rs.total_sales,
    rs.total_units,
    rs.total_sales / NULLIF(rs.total_customers, 0) AS sales_per_customer,
    rs.total_orders / NULLIF(rs.total_customers, 0) AS orders_per_customer,
    CASE 
        WHEN sp.population IS NULL THEN NULL
        ELSE rs.total_customers * 100000.0 / sp.population 
    END AS customers_per_100k,
    RANK() OVER (PARTITION BY rs.state ORDER BY rs.total_sales DESC) AS city_rank_in_state,
    SUM(rs.total_sales) OVER (PARTITION BY rs.state) AS state_total_sales,
    rs.total_sales / NULLIF(SUM(rs.total_sales) OVER (PARTITION BY rs.state), 0) * 100 AS pct_of_state_sales
FROM RegionSales rs
LEFT JOIN StatePopulation sp ON rs.state = sp.state
ORDER BY rs.total_sales DESC;

--Customer Lifetime Value (CLV) Analysis
WITH CustomerOrders AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.city,
        c.state,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent,
        DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) AS customer_span_days,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM sales.customers c
    JOIN sales.orders o ON c.customer_id = o.customer_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 4 -- Completed orders
    GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.state
)
SELECT 
    customer_id,
    customer_name,
    city,
    state,
    order_count,
    total_spent,
    customer_span_days,
    total_spent / NULLIF(order_count, 0) AS avg_order_value,
    CASE 
        WHEN customer_span_days = 0 THEN total_spent
        ELSE total_spent / (customer_span_days / 30.0) 
    END AS monthly_spending_rate,
    CASE 
        WHEN customer_span_days = 0 THEN total_spent * 12
        ELSE (total_spent / (customer_span_days / 365.0)) * 3 -- Projected 3-year value
    END AS estimated_3yr_clv,
    NTILE(5) OVER (ORDER BY total_spent DESC) AS value_segment
FROM CustomerOrders
ORDER BY estimated_3yr_clv DESC;

-- Customer orders with their total spending and favorite category
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    c.state,
    COUNT(o.order_id) AS total_orders,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent,
    (
        SELECT TOP 1 cat.category_name
        FROM production.products p
        JOIN production.categories cat ON p.category_id = cat.category_id
        JOIN sales.order_items oi2 ON p.product_id = oi2.product_id
        JOIN sales.orders o2 ON oi2.order_id = o2.order_id
        WHERE o2.customer_id = c.customer_id
        GROUP BY cat.category_name
        ORDER BY SUM(oi2.quantity) DESC
    ) AS favorite_category
FROM sales.customers c
LEFT JOIN sales.orders o ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.state
ORDER BY total_spent DESC;

-- Product performance grouped by brand
SELECT 
    b.brand_name,
    COUNT(DISTINCT p.product_id) AS product_count,
    SUM(s.quantity) AS total_inventory,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue,
    AVG(oi.list_price * (1 - oi.discount)) AS avg_selling_price,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) / NULLIF(SUM(oi.quantity), 0) AS revenue_per_unit
FROM production.brands b
JOIN production.products p ON b.brand_id = p.brand_id
LEFT JOIN production.stocks s ON p.product_id = s.product_id
LEFT JOIN sales.order_items oi ON p.product_id = oi.product_id
LEFT JOIN sales.orders o ON oi.order_id = o.order_id AND o.order_status = 4
GROUP BY b.brand_name
ORDER BY total_revenue DESC;

-- Monthly sales trends by category
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    c.category_name,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
JOIN production.products p ON oi.product_id = p.product_id
JOIN production.categories c ON p.category_id = c.category_id
WHERE o.order_status = 4 -- Completed orders
GROUP BY YEAR(o.order_date), MONTH(o.order_date), c.category_name
ORDER BY year, month, total_sales DESC;

-- Store performance comparison
SELECT 
    s.store_id,
    s.store_name,
    s.city,
    s.state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
    SUM(oi.quantity) AS total_units,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) / 
        NULLIF(COUNT(DISTINCT o.order_id), 0) AS avg_order_value,
    COUNT(DISTINCT st.staff_id) AS staff_count
FROM sales.stores s
LEFT JOIN sales.orders o ON s.store_id = o.store_id
LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
LEFT JOIN sales.staffs st ON s.store_id = st.store_id
WHERE o.order_status = 4 OR o.order_id IS NULL
GROUP BY s.store_id, s.store_name, s.city, s.state
ORDER BY total_sales DESC;


-- Order fulfillment timing analysis
SELECT 
    order_status,
    CASE order_status
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Processing'
        WHEN 3 THEN 'Rejected'
        WHEN 4 THEN 'Completed'
    END AS status_name,
    COUNT(*) AS order_count,
    AVG(DATEDIFF(DAY, order_date, shipped_date)) AS avg_days_to_ship,
    AVG(DATEDIFF(DAY, order_date, required_date)) AS avg_days_until_required,
    AVG(DATEDIFF(DAY, required_date, shipped_date)) AS avg_days_early_or_late
FROM sales.orders
GROUP BY order_status
ORDER BY order_status;

-- Product availability across stores
SELECT 
    p.product_id,
    p.product_name,
    b.brand_name,
    c.category_name,
    p.list_price,
    COUNT(DISTINCT s.store_id) AS stores_available,
    SUM(s.quantity) AS total_inventory,
    (SELECT COUNT(*) FROM sales.stores) AS total_stores,
    COUNT(DISTINCT s.store_id) * 100 / (SELECT COUNT(*) FROM sales.stores) AS pct_stores_with_product
FROM production.products p
JOIN production.brands b ON p.brand_id = b.brand_id
JOIN production.categories c ON p.category_id = c.category_id
LEFT JOIN production.stocks s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name, b.brand_name, c.category_name, p.list_price
ORDER BY pct_stores_with_product DESC, total_inventory DESC;
