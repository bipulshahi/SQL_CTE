# Multiple Views

## Key Difference: CTEs vs Views

**CTEs (Common Table Expressions):**
- Temporary, exist only during query execution
- Cannot be reused across different queries
- Created within a single SQL statement

**Views:**
- Persistent, stored in the database permanently
- Can be reused across unlimited queries
- Created once, queried multiple times
- Appear like regular tables to end users

When you use **multiple views**, you're creating several stored query definitions that can be used independently or together. This is perfect for applications where multiple users or reports need the same data structures.

***

## Example 1: Repeat Customer Analysis Using Views

### Problem Statement 1
**Business Question:** Analyze customer purchasing behavior to understand:
1. How many customers are repeat customers (made more than 1 order)?
2. What is the total sales generated from repeat customers?
3. What is the total number of customers overall?
4. What is the total sales from all customers?

### Step-by-Step Approach

**Step 1:** Create a VIEW that calculates total orders and total sales per customer  
**Step 2:** Create separate VIEWs or queries that use the first VIEW to answer different questions

### Complete Solution

**Step 1: Create the Base View**
```sql
CREATE VIEW vw_CustomerOrders AS
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    SUM(total) AS total_sales
FROM orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY customer_id;
```

**Now use the view to answer different questions:**

**Query 1: Get Repeat Customers Count**
```sql
SELECT 
    COUNT(*) AS repeat_customers,
    SUM(total_sales) AS sales_from_repeat_customers
FROM vw_CustomerOrders
WHERE total_orders > 1;
```

**Query 2: Get All Customer Statistics**
```sql
SELECT 
    COUNT(*) AS total_customers,
    SUM(total_sales) AS total_sales
FROM vw_CustomerOrders;
```

**Query 3: Get Combined Analysis (All 4 Metrics)**
```sql
SELECT 
    (SELECT COUNT(*) 
     FROM vw_CustomerOrders 
     WHERE total_orders > 1) AS repeat_customers,
    
    (SELECT SUM(total_sales) 
     FROM vw_CustomerOrders 
     WHERE total_orders > 1) AS sales_from_repeat_customers,
    
    (SELECT COUNT(*) 
     FROM vw_CustomerOrders) AS total_customers,
    
    (SELECT SUM(total_sales) 
     FROM vw_CustomerOrders) AS total_sales;
```

### Detailed Explanation

**Creating the View:**
```sql
CREATE VIEW vw_CustomerOrders AS
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    SUM(total) AS total_sales
FROM orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY customer_id;
```

**Naming Convention:** `vw_` prefix helps identify views in the database

**What the view contains:**
- **customer_id:** Identifies the customer
- **total_orders:** Count of orders placed in last year
- **total_sales:** Total spending in last year
- Grouped by customer for one row per customer

**Using the View - Query 1:**
```sql
SELECT 
    COUNT(*) AS repeat_customers,
    SUM(total_sales) AS sales_from_repeat_customers
FROM vw_CustomerOrders
WHERE total_orders > 1;
```

- Treats `vw_CustomerOrders` like a regular table
- `WHERE total_orders > 1` filters for repeat customers
- `COUNT(*)` counts how many repeat customers exist
- `SUM(total_sales)` totals their sales

**Using the View - Query 2:**
```sql
SELECT 
    COUNT(*) AS total_customers,
    SUM(total_sales) AS total_sales
FROM vw_CustomerOrders;
```

- No WHERE clause - includes ALL customers
- `COUNT(*)` counts total unique customers
- `SUM(total_sales)` totals all sales

**Using the View - Query 3 (Combined):**
This combines both queries into one:
```sql
SELECT 
    (SELECT COUNT(*) 
     FROM vw_CustomerOrders 
     WHERE total_orders > 1) AS repeat_customers,
    
    (SELECT SUM(total_sales) 
     FROM vw_CustomerOrders 
     WHERE total_orders > 1) AS sales_from_repeat_customers,
    
    (SELECT COUNT(*) 
     FROM vw_CustomerOrders) AS total_customers,
    
    (SELECT SUM(total_sales) 
     FROM vw_CustomerOrders) AS total_sales;
```

This gives you all 4 metrics in a single row:

| repeat_customers | sales_from_repeat_customers | total_customers | total_sales |
|-----------------|----------------------------|-----------------|-------------|
| 2 | 13,451.74 | 30 | 58,901.79 |

### Key Advantage of Views Here

The view `vw_CustomerOrders` is now **permanent** in your database. Any analyst can use it:
- In reports
- In dashboards
- In applications
- Without needing to rewrite the complex GROUP BY logic each time

***

## Example 2: Product Performance Analysis Using Views

### Problem Statement 2
**Business Question:** Analyze product inventory and sales to understand:
1. How many products are out of stock?
2. What is the total potential revenue lost from out-of-stock products?
3. How many products are available in stock?
4. What is the average stock level across all in-stock products?

### Complete Solution

**Step 1: Create the Base View for Product Inventory**
```sql
CREATE VIEW vw_ProductInventory AS
SELECT 
    product_id,
    name AS product_name,
    price,
    stock,
    CASE 
        WHEN stock = 0 THEN 'Out of Stock'
        WHEN stock < 50 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    (price * stock) AS inventory_value
FROM products;
```

**Step 2: Create Specialized Views for Different Analyses**

**View for Out-of-Stock Analysis:**
```sql
CREATE VIEW vw_OutOfStockAnalysis AS
SELECT 
    COUNT(*) AS out_of_stock_count,
    SUM(price) AS potential_lost_revenue,
    AVG(price) AS avg_product_price
FROM vw_ProductInventory
WHERE stock_status = 'Out of Stock';
```

**View for In-Stock Analysis:**
```sql
CREATE VIEW vw_InStockAnalysis AS
SELECT 
    COUNT(*) AS in_stock_count,
    AVG(stock) AS avg_stock_level,
    SUM(inventory_value) AS total_inventory_value
FROM vw_ProductInventory
WHERE stock_status = 'In Stock';
```

**Now Query These Views:**

**Query 1: Out-of-Stock Metrics**
```sql
SELECT * FROM vw_OutOfStockAnalysis;
```

Result:
| out_of_stock_count | potential_lost_revenue | avg_product_price |
|-------------------|----------------------|------------------|
| 3 | 800.00 | 266.67 |

**Query 2: In-Stock Metrics**
```sql
SELECT * FROM vw_InStockAnalysis;
```

Result:
| in_stock_count | avg_stock_level | total_inventory_value |
|----------------|-----------------|----------------------|
| 5 | 128.0000 | 31,400.00 |

**Query 3: Combined Analysis**
```sql
SELECT 
    (SELECT out_of_stock_count 
     FROM vw_OutOfStockAnalysis) AS out_of_stock_count,
    
    (SELECT potential_lost_revenue 
     FROM vw_OutOfStockAnalysis) AS potential_lost_revenue,
    
    (SELECT in_stock_count 
     FROM vw_InStockAnalysis) AS in_stock_count,
    
    (SELECT avg_stock_level 
     FROM vw_InStockAnalysis) AS avg_stock_level;
```

Result:
| out_of_stock_count | potential_lost_revenue | in_stock_count | avg_stock_level |
|-------------------|----------------------|----------------|-----------------|
| 3 | 800.00 | 5 | 128.0000 |

### Detailed Explanation

**Creating vw_ProductInventory (Base View):**
```sql
CREATE VIEW vw_ProductInventory AS
SELECT 
    product_id,
    name AS product_name,
    price,
    stock,
    CASE 
        WHEN stock = 0 THEN 'Out of Stock'
        WHEN stock < 50 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    (price * stock) AS inventory_value
FROM products;
```

This base view:
- Adds a **stock_status** column for easy categorization
- Calculates **inventory_value** (how much value is sitting in stock)
- Serves as the foundation for other views

**Creating vw_OutOfStockAnalysis (Specialized View):**
```sql
CREATE VIEW vw_OutOfStockAnalysis AS
SELECT 
    COUNT(*) AS out_of_stock_count,
    SUM(price) AS potential_lost_revenue,
    AVG(price) AS avg_product_price
FROM vw_ProductInventory
WHERE stock_status = 'Out of Stock';
```

**Key Points:**
- Uses the previous view `vw_ProductInventory` as its source
- Filters to only **'Out of Stock'** items
- Pre-calculates metrics that might be queried frequently

**Creating vw_InStockAnalysis (Specialized View):**
```sql
CREATE VIEW vw_InStockAnalysis AS
SELECT 
    COUNT(*) AS in_stock_count,
    AVG(stock) AS avg_stock_level,
    SUM(inventory_value) AS total_inventory_value
FROM vw_ProductInventory
WHERE stock_status = 'In Stock';
```

This view:
- Filters to only **'In Stock'** items
- Shows inventory health metrics
- Pre-calculates for performance

### View Hierarchy

```
vw_ProductInventory (Base)
    ↓
    ├─→ vw_OutOfStockAnalysis (Specialized)
    ├─→ vw_InStockAnalysis (Specialized)
    └─→ Can be used directly for custom queries
```

***

## Example 3: Customer Geography Analysis Using Views

### Problem Statement 3
**Business Question:** Analyze customer distribution geographically to understand:
1. How many customers are from Maharashtra state?
2. What is the total order value from Maharashtra customers?
3. How many customers are from Mumbai city?
4. What is the average order value per customer from Mumbai?

### Complete Solution

**Step 1: Create Base View with Customer Orders**
```sql
CREATE VIEW vw_CustomerLocationOrders AS
SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.city,
    c.state,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city, c.state;
```

**Step 2: Create Specialized Views**

**View for State-Level Analysis:**
```sql
CREATE VIEW vw_StatePerformance AS
SELECT 
    state,
    COUNT(DISTINCT customer_id) AS customer_count,
    SUM(total_spent) AS total_revenue,
    AVG(total_spent) AS avg_customer_value,
    COUNT(DISTINCT CASE WHEN total_orders > 1 THEN customer_id END) AS repeat_customers
FROM vw_CustomerLocationOrders
GROUP BY state;
```

**View for City-Level Analysis:**
```sql
CREATE VIEW vw_CityPerformance AS
SELECT 
    city,
    state,
    COUNT(DISTINCT customer_id) AS customer_count,
    SUM(total_spent) AS total_revenue,
    AVG(total_spent) AS avg_customer_value,
    MAX(total_spent) AS top_customer_value
FROM vw_CustomerLocationOrders
GROUP BY city, state;
```

### Now Query These Views

**Query 1: Get Maharashtra Performance**
```sql
SELECT * FROM vw_StatePerformance
WHERE state = 'Maharashtra';
```

Result:
| state | customer_count | total_revenue | avg_customer_value | repeat_customers |
|-------|----------------|---------------|------------------|-----------------|
| Maharashtra | 5 | 15,300.98 | 3,060.20 | 3 |

**Query 2: Get Mumbai Performance**
```sql
SELECT * FROM vw_CityPerformance
WHERE city = 'Mumbai';
```

Result:
| city | state | customer_count | total_revenue | avg_customer_value | top_customer_value |
|------|-------|----------------|---------------|------------------|------------------|
| Mumbai | Maharashtra | 3 | 12,100.25 | 4,033.42 | 6,500.00 |

**Query 3: Combined Geography Metrics**
```sql
SELECT 
    (SELECT customer_count 
     FROM vw_StatePerformance 
     WHERE state = 'Maharashtra') AS maharashtra_customers,
    
    (SELECT total_revenue 
     FROM vw_StatePerformance 
     WHERE state = 'Maharashtra') AS maharashtra_revenue,
    
    (SELECT customer_count 
     FROM vw_CityPerformance 
     WHERE city = 'Mumbai') AS mumbai_customers,
    
    (SELECT avg_customer_value 
     FROM vw_CityPerformance 
     WHERE city = 'Mumbai') AS avg_mumbai_customer_value;
```

Result:
| maharashtra_customers | maharashtra_revenue | mumbai_customers | avg_mumbai_customer_value |
|----------------------|-------------------|-----------------|--------------------------|
| 5 | 15,300.98 | 3 | 4,033.42 |

### Detailed Explanation

**Creating vw_CustomerLocationOrders (Base View):**
```sql
CREATE VIEW vw_CustomerLocationOrders AS
SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.city,
    c.state,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city, c.state;
```

**Important Points:**
- **LEFT JOIN:** Includes customers even if they have no orders
- **COALESCE:** Converts NULL to 0 for customers with no orders
- One row per customer with their location and order stats

**Creating vw_StatePerformance (State-Level View):**
```sql
CREATE VIEW vw_StatePerformance AS
SELECT 
    state,
    COUNT(DISTINCT customer_id) AS customer_count,
    SUM(total_spent) AS total_revenue,
    AVG(total_spent) AS avg_customer_value,
    COUNT(DISTINCT CASE WHEN total_orders > 1 THEN customer_id END) AS repeat_customers
FROM vw_CustomerLocationOrders
GROUP BY state;
```

This view:
- Groups by **state** (upper level aggregation)
- Counts unique customers per state
- Shows total and average revenue per state
- Identifies repeat customers per state

**Creating vw_CityPerformance (City-Level View):**
```sql
CREATE VIEW vw_CityPerformance AS
SELECT 
    city,
    state,
    COUNT(DISTINCT customer_id) AS customer_count,
    SUM(total_spent) AS total_revenue,
    AVG(total_spent) AS avg_customer_value,
    MAX(total_spent) AS top_customer_value
FROM vw_CustomerLocationOrders
GROUP BY city, state;
```

This view:
- Groups by **city** (more granular level)
- Shows city-level performance metrics
- Includes top customer value per city for insights

### View Hierarchy

```
vw_CustomerLocationOrders (Base - joins customers & orders)
    ↓
    ├─→ vw_StatePerformance (State aggregation)
    └─→ vw_CityPerformance (City aggregation)
```

***

## When to Use Views vs CTEs - Decision Guide

| Scenario | Use Views | Use CTE |
|----------|-----------|---------|
| **One-time analysis** | ❌ | ✅ |
| **Reuse across multiple queries** | ✅ | ❌ |
| **Team collaboration** | ✅ | ❌ |
| **Application queries** | ✅ | ❌ |
| **Breaking down single complex query** | ❌ | ✅ |
| **Security/data access control** | ✅ | ❌ |
| **Dashboard/report definitions** | ✅ | ❌ |
| **Complex temporary calculation** | ❌ | ✅ |

***

## Advantages of Using Multiple Views

### 1. **Modularity**
Break complex logic into smaller, manageable views:
```
vw_ProductInventory (foundational)
    ↓
    ├─→ vw_OutOfStockAnalysis
    ├─→ vw_InStockAnalysis
    └─→ vw_LowStockWarning
```

### 2. **Reusability**
Each view can be used independently:
```sql
-- In Report 1
SELECT * FROM vw_StatePerformance;

-- In Report 2
SELECT * FROM vw_CityPerformance;

-- In Dashboard
SELECT * FROM vw_CustomerLocationOrders;
```

### 3. **Performance**
Views can be cached by the database optimizer:
```sql
-- Query runs fast because the view might be pre-computed
SELECT * FROM vw_StatePerformance WHERE state = 'Maharashtra';
```

### 4. **Maintainability**
Update logic in one place, affects all queries:
```sql
-- Change the base view once
ALTER VIEW vw_CustomerLocationOrders AS ...
-- All dependent views are automatically updated
```

### 5. **Security**
Restrict access to specific columns:
```sql
-- Users can only see vw_StatePerformance (no individual customer data)
-- They cannot access raw customers table
GRANT SELECT ON vw_StatePerformance TO analyst_role;
```

***

## Practice Exercise

Create views for your ecommerce database to:

1. **vw_ProductCategorySummary:** Summary of products by category
2. **vw_OrdersWithCustomerDetails:** Orders joined with customer info
3. **vw_CategoryPerformance:** Revenue metrics per category

Then query them together:

```sql
CREATE VIEW vw_ProductCategorySummary AS
SELECT 
    c.category_id,
    c.name AS category_name,
    COUNT(p.product_id) AS product_count,
    AVG(p.price) AS avg_price,
    SUM(p.stock) AS total_stock
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.name;

CREATE VIEW vw_OrdersWithCustomerDetails AS
SELECT 
    o.order_id,
    o.customer_id,
    c.name AS customer_name,
    c.city,
    c.state,
    o.order_date,
    o.total AS order_amount,
    o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

CREATE VIEW vw_CategoryPerformance AS
SELECT 
    p.category_id,
    cat.name AS category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.subtotal) AS total_revenue,
    AVG(oi.subtotal) AS avg_order_value
FROM products p
JOIN categories cat ON p.category_id = cat.category_id
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category_id, cat.name;
```

Now query them:
```sql
-- View all analytics at once
SELECT 
    (SELECT COUNT(*) FROM vw_ProductCategorySummary) AS total_categories,
    (SELECT SUM(total_stock) FROM vw_ProductCategorySummary) AS total_products_in_stock,
    (SELECT SUM(total_revenue) FROM vw_CategoryPerformance) AS all_time_revenue;
```
