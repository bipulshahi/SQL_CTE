# Multiple CTEs with Reusability - Complete Guide

**Key Idea:** Once you create a CTE, you can reference it **multiple times** in the same query - even within **subqueries** or **inline SELECT statements**. This eliminates code duplication and makes your queries cleaner.

Think of CTEs as **temporary building blocks** that you can use again and again within the same SQL statement.

---

## Example 1 (From Your Image): Repeat Customer Analysis

### Problem Statement 1
**Business Question:** Analyze customer purchasing behavior to understand:
1. How many customers are repeat customers (made more than 1 order)?
2. What is the total sales generated from repeat customers?
3. What is the total number of customers overall?
4. What is the total sales from all customers?

This helps the business understand the value of customer retention.

### Step-by-Step Approach

**Step 1:** Create a CTE that calculates total orders and total sales per customer  
**Step 2:** Use this CTE **4 different times** to answer different questions:
   - Count repeat customers
   - Sum sales from repeat customers
   - Count all customers
   - Sum all sales

### Complete Solution with Explanation

```sql
WITH customerorders AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(total) AS total_sales
    FROM orders
    WHERE order_date >= DATEADD(YEAR, -1, CURRENT_DATE)
    GROUP BY customer_id
)

SELECT 
    -- How many repeat customers? (more than 1 order)
    (SELECT COUNT(*) 
     FROM customerorders 
     WHERE total_orders > 1) AS repeat_customers,
    
    -- Total sales from repeat customers
    (SELECT SUM(total_sales) 
     FROM customerorders 
     WHERE total_orders > 1) AS sales_from_repeat_customers,
    
    -- Total number of customers
    (SELECT COUNT(*) 
     FROM customerorders) AS total_customers,
    
    -- Total sales from all customers
    (SELECT SUM(total_sales) 
     FROM customerorders) AS total_sales;
```

### Line-by-Line Breakdown

**CTE Definition:**
```sql
WITH customerorders AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(total) AS total_sales
    FROM orders
    WHERE order_date >= DATEADD(YEAR, -1, CURRENT_DATE)
    GROUP BY customer_id
)
```

- **customerorders:** Name of our temporary result set
- **COUNT(order_id):** Counts how many orders each customer made
- **SUM(total):** Sums up the total spending per customer
- **WHERE order_date >= DATEADD(YEAR, -1, CURRENT_DATE):** Only includes orders from the last year
- **GROUP BY customer_id:** One row per customer

**Main Query - Using CTE 4 Times:**

**1st Use - Repeat Customers Count:**
```sql
(SELECT COUNT(*) 
 FROM customerorders 
 WHERE total_orders > 1) AS repeat_customers
```
- Counts customers who placed **more than 1 order**
- These are "repeat" or "returning" customers

**2nd Use - Sales from Repeat Customers:**
```sql
(SELECT SUM(total_sales) 
 FROM customerorders 
 WHERE total_orders > 1) AS sales_from_repeat_customers
```
- Adds up all sales from repeat customers only
- Shows how valuable repeat customers are

**3rd Use - Total Customers:**
```sql
(SELECT COUNT(*) 
 FROM customerorders) AS total_customers
```
- Counts **all customers** (including one-time buyers)

**4th Use - Total Sales:**
```sql
(SELECT SUM(total_sales) 
 FROM customerorders) AS total_sales
```
- Sums **all sales** from all customers

### MySQL-Compatible Version (for your database)

Since MySQL doesn't have `DATEADD`, here's the corrected version:

```sql
WITH customerorders AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(total) AS total_sales
    FROM orders
    WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY customer_id
)

SELECT 
    (SELECT COUNT(*) 
     FROM customerorders 
     WHERE total_orders > 1) AS repeat_customers,
    
    (SELECT SUM(total_sales) 
     FROM customerorders 
     WHERE total_orders > 1) AS sales_from_repeat_customers,
    
    (SELECT COUNT(*) 
     FROM customerorders) AS total_customers,
    
    (SELECT SUM(total_sales) 
     FROM customerorders) AS total_sales;
```

### Expected Output

Your result will be a **single row** with 4 columns:

| repeat_customers | sales_from_repeat_customers | total_customers | total_sales |
|-----------------|----------------------------|-----------------|-------------|
| 2 | 13,451.74 | 30 | 58,901.79 |

### What This Tells Us

- **Repeat customers** are only a small portion of total customers
- But they generate a significant amount of revenue
- Business should focus on retention strategies!

***

## Example 2: Product Performance Analysis

### Problem Statement 2
**Business Question:** Analyze product inventory and sales to understand:
1. How many products are out of stock?
2. What is the total potential revenue lost from out-of-stock products (based on price)?
3. How many products are available in stock?
4. What is the average stock level across all in-stock products?

This helps the business with inventory management decisions.

### Step-by-Step Approach

**Step 1:** Create a CTE that gets product details with stock status  
**Step 2:** Use this CTE **4 different times** to answer different questions:
   - Count out-of-stock products
   - Calculate potential lost revenue
   - Count in-stock products
   - Calculate average stock level

### Complete Solution

```sql
WITH ProductInventory AS (
    SELECT 
        product_id,
        name AS product_name,
        price,
        stock,
        CASE 
            WHEN stock = 0 THEN 'Out of Stock'
            WHEN stock < 50 THEN 'Low Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM products
)

SELECT 
    -- Number of out-of-stock products
    (SELECT COUNT(*) 
     FROM ProductInventory 
     WHERE stock_status = 'Out of Stock') AS out_of_stock_count,
    
    -- Potential revenue lost (sum of prices of out-of-stock items)
    (SELECT SUM(price) 
     FROM ProductInventory 
     WHERE stock_status = 'Out of Stock') AS potential_lost_revenue,
    
    -- Number of in-stock products
    (SELECT COUNT(*) 
     FROM ProductInventory 
     WHERE stock_status = 'In Stock') AS in_stock_count,
    
    -- Average stock level for in-stock products
    (SELECT AVG(stock) 
     FROM ProductInventory 
     WHERE stock_status = 'In Stock') AS avg_stock_level;
```

### Detailed Explanation

**CTE Definition:**
```sql
WITH ProductInventory AS (
    SELECT 
        product_id,
        name AS product_name,
        price,
        stock,
        CASE 
            WHEN stock = 0 THEN 'Out of Stock'
            WHEN stock < 50 THEN 'Low Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM products
)
```

- Creates a **stock_status** column using CASE logic
- **stock = 0:** Out of Stock
- **stock < 50:** Low Stock (warning level)
- **else:** In Stock (healthy inventory)

**Main Query - Using CTE 4 Times:**

**1st Use - Out of Stock Count:**
```sql
(SELECT COUNT(*) 
 FROM ProductInventory 
 WHERE stock_status = 'Out of Stock')
```
- Counts products with zero inventory

**2nd Use - Potential Lost Revenue:**
```sql
(SELECT SUM(price) 
 FROM ProductInventory 
 WHERE stock_status = 'Out of Stock')
```
- If each out-of-stock product could sell 1 unit, this is the revenue
- Shows opportunity cost of stockouts

**3rd Use - In Stock Count:**
```sql
(SELECT COUNT(*) 
 FROM ProductInventory 
 WHERE stock_status = 'In Stock')
```
- Counts products with healthy inventory

**4th Use - Average Stock:**
```sql
(SELECT AVG(stock) 
 FROM ProductInventory 
 WHERE stock_status = 'In Stock')
```
- Shows typical inventory level
- Helps with reordering decisions

### Expected Output

| out_of_stock_count | potential_lost_revenue | in_stock_count | avg_stock_level |
|-------------------|----------------------|----------------|-----------------|
| 3 | 800.00 | 5 | 128.0000 |

***

## Example 3: Customer City and State Analysis

### Problem Statement 3
**Business Question:** Analyze customer distribution geographically to understand:
1. How many customers are from Maharashtra state?
2. What is the total order value from Maharashtra customers?
3. How many customers are from Mumbai city?
4. What is the average order value per customer from Mumbai?

This helps the business understand regional performance and target marketing.

### Complete Solution

```sql
WITH CustomerOrders AS (
    SELECT 
        c.customer_id,
        c.name AS customer_name,
        c.city,
        c.state,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(o.total), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name, c.city, c.state
)

SELECT 
    -- Customers from Maharashtra
    (SELECT COUNT(*) 
     FROM CustomerOrders 
     WHERE state = 'Maharashtra') AS maharashtra_customers,
    
    -- Total revenue from Maharashtra
    (SELECT SUM(total_spent) 
     FROM CustomerOrders 
     WHERE state = 'Maharashtra') AS maharashtra_revenue,
    
    -- Customers from Mumbai
    (SELECT COUNT(*) 
     FROM CustomerOrders 
     WHERE city = 'Mumbai') AS mumbai_customers,
    
    -- Average spending per Mumbai customer
    (SELECT AVG(total_spent) 
     FROM CustomerOrders 
     WHERE city = 'Mumbai') AS avg_mumbai_customer_value;
```

### Explanation

**CTE Definition:**
- Joins **customers** with **orders**
- Uses **LEFT JOIN** to include customers with no orders
- **COALESCE(SUM(o.total), 0):** Handles NULL values for customers with no orders
- Groups by customer and their location

**Main Query:**
- Uses the CTE **4 times** for different geographical analyses
- First two focus on **state-level** (Maharashtra)
- Last two focus on **city-level** (Mumbai)

---

## Why This Pattern is Powerful

### Without CTE (Messy Approach):
You would need to repeat the same complex joins 4 times:

```sql
SELECT 
    (SELECT COUNT(*) 
     FROM customers c 
     LEFT JOIN orders o ON c.customer_id = o.customer_id 
     WHERE state = 'Maharashtra' 
     GROUP BY c.customer_id) AS maharashtra_customers,
    
    (SELECT SUM(total_spent) 
     FROM (SELECT c.customer_id, SUM(o.total) as total_spent
           FROM customers c 
           LEFT JOIN orders o ON c.customer_id = o.customer_id 
           WHERE state = 'Maharashtra' 
           GROUP BY c.customer_id) AS subq) AS maharashtra_revenue
    -- ... and so on
```

This is:
- **Repetitive** (same join logic multiple times)
- **Hard to read** (nested subqueries everywhere)
- **Error-prone** (easy to make mistakes in repeated code)
- **Slower** (database might compute the same thing multiple times)

### With CTE (Clean Approach):
```sql
WITH CustomerOrders AS (
    -- Define ONCE
)
SELECT 
    (SELECT ... FROM CustomerOrders ...) AS metric1,
    (SELECT ... FROM CustomerOrders ...) AS metric2,
    (SELECT ... FROM CustomerOrders ...) AS metric3,
    (SELECT ... FROM CustomerOrders ...) AS metric4;
```

This is:
- **DRY Principle** (Don't Repeat Yourself)
- **Readable** (clear what data we're working with)
- **Maintainable** (change logic in one place)
- **Potentially faster** (optimizer can cache the CTE)

---

## Key Takeaways

1. **One CTE, Multiple Uses:** Define complex logic once, use it many times in the same query

2. **Inline SELECT Statements:** You can use CTEs inside SELECT clauses as scalar subqueries

3. **Performance:** The database may optimize repeated CTE usage (though not guaranteed)

4. **Readability:** Makes complex analytical queries much easier to understand

5. **Business Analytics:** Perfect for dashboard queries that need multiple metrics from the same dataset

***

## Practice Exercise for You

Try creating a CTE and using it multiple times to answer:

**Using the ecommerce_db:**
1. How many products are in the "Electronics" category?
2. What is the average price of Electronics products?
3. How many products are in the "Clothing" category?
4. What is the total inventory value (price × stock) of Clothing products?

**Solution:**
```sql
WITH ProductDetails AS (
    SELECT 
        p.product_id,
        p.name,
        p.price,
        p.stock,
        c.name AS category_name,
        (p.price * p.stock) AS inventory_value
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
)

SELECT 
    (SELECT COUNT(*) 
     FROM ProductDetails 
     WHERE category_name = 'Electronics') AS electronics_count,
    
    (SELECT AVG(price) 
     FROM ProductDetails 
     WHERE category_name = 'Electronics') AS avg_electronics_price,
    
    (SELECT COUNT(*) 
     FROM ProductDetails 
     WHERE category_name = 'Clothing') AS clothing_count,
    
    (SELECT SUM(inventory_value) 
     FROM ProductDetails 
     WHERE category_name = 'Clothing') AS clothing_inventory_value;
```
