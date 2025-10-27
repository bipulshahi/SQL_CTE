-- Basic CTE Syntax

/*
WITH cte_name AS (
    -- CTE Definition: Write your query here
    SELECT column1, column2
    FROM table_name
    WHERE condition
)
-- Main Query: Use the CTE here
SELECT column1, column2
FROM cte_name
WHERE another_condition;
*/

-- Simple Beginner Example
-- Let's find all employees and their total sales amount

-- Subqueries 
SELECT 
    e.employee_name,
    (
        SELECT SUM(s.sale_amount)
        FROM sales s
        WHERE s.employee_id = e.employee_id
    ) AS total_sales
FROM employees e
ORDER BY total_sales DESC;


-- Step 1: Create a CTE to calculate total sales per employee

select * from employees;
select * from sales;

WITH EmployeeSales AS (
    SELECT 
        employee_id,
        SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY employee_id
)
-- Step 2: Use the CTE in the main query
SELECT 
    e.employee_name,
    es.total_sales
FROM employees e
JOIN EmployeeSales es ON e.employee_id = es.employee_id
ORDER BY es.total_sales DESC;




/* Find customers whose total spending on orders is higher than the average spending across all customers. 
Display the customer_id, customer_name, and total_spent for these customers, ordered by total spending in descending order.
*/

SELECT 
    c.customer_id,
    c.name AS customer_name,
    SUM(o.total) AS total_spent
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING SUM(o.total) > (
    SELECT AVG(total_spent)
    FROM (
        SELECT 
            customer_id, 
            SUM(total) AS total_spent
        FROM orders
        GROUP BY customer_id
    ) AS sub
)
ORDER BY total_spent DESC;

-- Using CTE

WITH CustomerSpending AS (
    -- Step 1: Calculate how much each customer has spent
    SELECT 
        c.customer_id, 
        c.name AS customer_name, 
        SUM(o.total) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
),
AverageSpending AS (
    -- Step 2: Calculate the average spending from the previous CTE
    SELECT AVG(total_spent) AS avg_spent
    FROM CustomerSpending
)
-- Step 3: Filter and display customers above average
SELECT 
    cs.customer_id, 
    cs.customer_name, 
    cs.total_spent
FROM CustomerSpending cs
JOIN AverageSpending avgsp ON cs.total_spent > avgsp.avg_spent
ORDER BY cs.total_spent DESC;



-- Find products that have never been purchased. Display the product_id, product_name, and category_name of these products, ordered by product name.

-- Sub-Querries
SELECT 
    p.product_id,
    p.name AS product_name,
    c.name AS category_name
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.product_id NOT IN (
    SELECT DISTINCT oi.product_id
    FROM order_items oi
)
ORDER BY p.name;

-- corelated
SELECT 
    p.product_id,
    p.name AS product_name,
    c.name AS category_name
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.product_id
)
ORDER BY p.name;



-- CTE
select * from products;
select * from order_items;
select * from categories;

WITH PurchasedProducts AS (
    -- Step 1: Get all product IDs that have been purchased
    SELECT DISTINCT p.product_id
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
)
-- Step 2: Find products that are NOT in the purchased list
SELECT 
    p.product_id, 
    p.name AS product_name, 
    c.name AS category_name,
    pp.product_id AS purchased_product_id
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN PurchasedProducts pp ON p.product_id = pp.product_id
WHERE pp.product_id IS NULL  -- This means the product was NOT found in PurchasedProducts
ORDER BY p.name;



-- Find the top 3 products by quantity purchased for each customer. Return customer_id, customer_name, product_name, and total_quantity, ordered by customer_id and rank.
WITH CustomerProductPurchase AS (
    -- Step 1: Calculate total quantity of each product per customer
    SELECT  
        c.customer_id,  
        c.name AS customer_name, 
        p.name AS product_name, 
        SUM(oi.quantity) AS total_quantity
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.name, p.name
),
TopProducts AS (
    -- Step 2: Rank products for each customer
    SELECT  
        cpp.customer_id, 
        cpp.customer_name, 
        cpp.product_name,  
        cpp.total_quantity,
        (
            -- This subquery counts how many products have higher quantity
            SELECT COUNT(*) + 1
            FROM CustomerProductPurchase cpp2
            WHERE cpp2.customer_id = cpp.customer_id
            AND cpp2.total_quantity > cpp.total_quantity
        ) AS product_rank
    FROM CustomerProductPurchase cpp
)
-- Step 3: Filter to top 3 only
SELECT 
    customer_id, 
    customer_name, 
    product_name, 
    total_quantity
FROM TopProducts
WHERE product_rank <= 3
ORDER BY customer_id, product_rank;


WITH CustomerProductPurchase AS (
    SELECT  c.customer_id,  c.name AS customer_name, p.name AS product_name, SUM(oi.quantity) AS total_quantity
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.name, p.name
),
TopProducts AS (
    SELECT  cpp.customer_id, cpp.customer_name, cpp.product_name,  cpp.total_quantity,
        (
            SELECT COUNT(*)
            FROM CustomerProductPurchase cpp2
            WHERE cpp2.customer_id = cpp.customer_id
            AND cpp2.total_quantity > cpp.total_quantity
        ) + 1 AS product_rank
    FROM CustomerProductPurchase cpp
)
SELECT customer_id, customer_name, product_name, total_quantity
FROM TopProducts
WHERE product_rank <= 3
ORDER BY customer_id, product_rank;




