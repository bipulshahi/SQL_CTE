# CTEs and Views in MySQL

## Part 1: Understanding CTEs - Step by Step

### What is a CTE (Common Table Expression)?

A **CTE** is a temporary named result set that exists only during the execution of a query. Think of it as a temporary table that you create on-the-fly to simplify your complex queries.

**Key Points:**
- Defined using the **WITH** keyword
- Can be referenced multiple times within the same query
- Makes complex queries more readable and maintainable
- Only exists during query execution (not permanently stored)

### Basic CTE Syntax

```sql
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
```

### Simple Beginner Example

Let's find all employees and their total sales amount:

**Step 1: Create a CTE to calculate total sales per employee**
```sql
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
```

**Explanation:**
- **WITH EmployeeSales AS**: This creates a temporary table called `EmployeeSales`
- Inside the CTE, we calculate the **total_sales** for each **employee_id**
- In the main query, we join this CTE with the **employees** table to get employee names
- Finally, we order results by total sales in descending order

***

## Part 2: Question 1 from PPT - Customers Above Average Spending

### Problem Statement
Find customers whose total spending on orders is higher than the average spending across all customers. Display the customer_id, customer_name, and total_spent for these customers, ordered by total spending in descending order.

### Step-by-Step Approach

**Step 1:** Calculate total spending for each customer  
**Step 2:** Calculate average spending across all customers  
**Step 3:** Filter customers who spent more than average  
**Step 4:** Display and sort results

### Solution with Detailed Explanation

```sql
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
```

### Line-by-Line Breakdown

1. **CustomerSpending CTE:**
   - Joins **customers** table with **orders** table
   - Groups by customer and calculates their total spending using `SUM(o.total)`

2. **AverageSpending CTE:**
   - Takes the results from `CustomerSpending`
   - Calculates the average of all `total_spent` values

3. **Main Query:**
   - Joins both CTEs
   - Filters to show only customers where `total_spent > avg_spent`
   - Sorts by total spending in descending order

### Expected Output
This will show customers like "Aarav Sharma", "Riya Nair", etc., who have spent more than the average.

***

## Part 3: Question 2 from PPT - Products Never Purchased

### Problem Statement
Find products that have never been purchased. Display the product_id, product_name, and category_name of these products, ordered by product name.

### Step-by-Step Approach

**Step 1:** Identify all products that have been purchased  
**Step 2:** Compare all products with purchased products  
**Step 3:** Find products with no purchases (using LEFT JOIN and NULL check)

### Solution with Detailed Explanation

```sql
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
    c.name AS category_name
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN PurchasedProducts pp ON p.product_id = pp.product_id
WHERE pp.product_id IS NULL  -- This means the product was NOT found in PurchasedProducts
ORDER BY p.name;
```

### Understanding the Logic

1. **PurchasedProducts CTE:**
   - Joins **products** with **order_items** to find all products that appear in orders
   - Uses `DISTINCT` to avoid duplicates (if a product was purchased multiple times)

2. **Main Query:**
   - `LEFT JOIN PurchasedProducts`: Keeps all products, even those without matches
   - `WHERE pp.product_id IS NULL`: Shows only rows where there was NO match (unpurchased products)

### Why LEFT JOIN Works Here

- **INNER JOIN** would only show products that were purchased
- **LEFT JOIN** shows all products, and marks unpurchased ones with NULL values
- This NULL check helps us find unpurchased products

### Expected Output
In your data, products like "Smartphone" (stock = 0) and "Running Shoes" (stock = 0) might appear here because no order_items reference them.

***

## Part 4: Question 3 from PPT - Top 3 Products Per Customer

### Problem Statement
Find the top 3 products by quantity purchased for each customer. Return customer_id, customer_name, product_name, and total_quantity, ordered by customer_id and rank.

### Step-by-Step Approach

**Step 1:** Calculate total quantity of each product purchased by each customer  
**Step 2:** Rank products for each customer based on quantity  
**Step 3:** Filter to get only top 3 products per customer  
**Step 4:** Display results sorted by customer and rank

### Solution with Detailed Explanation

```sql
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
```

### Understanding the Ranking Logic

The tricky part is the **product_rank** calculation:
```sql
(SELECT COUNT(*) + 1
 FROM CustomerProductPurchase cpp2
 WHERE cpp2.customer_id = cpp.customer_id
 AND cpp2.total_quantity > cpp.total_quantity)
```

**How it works:**
- For each product, count how many OTHER products from the SAME customer have HIGHER quantity
- Add 1 to get the rank (highest quantity = rank 1)

**Example:**
- If Customer 1 bought: Product A (100 qty), Product B (50 qty), Product C (30 qty)
- Product A has 0 products above it → rank = 0 + 1 = 1 ✓
- Product B has 1 product above it → rank = 1 + 1 = 2 ✓
- Product C has 2 products above it → rank = 2 + 1 = 3 ✓

***

## Part 5: Introduction to Views

### What is a View?

A **View** is a virtual table that stores a query definition in the database. Unlike CTEs, views are **permanently stored** and can be reused across multiple queries.

**Key Differences from CTE:**
- **Persistence:** Views are stored in the database; CTEs exist only during query execution
- **Reusability:** Views can be used in unlimited queries; CTEs only in the same query
- **Access Control:** Views can restrict data access for security; CTEs cannot

### View Syntax

```sql
CREATE VIEW view_name AS
SELECT column1, column2, column3
FROM table_name
WHERE condition;
```

### Why Use Views?

1. **Code Reusability:** Write complex join logic once, use many times
2. **Security:** Show only specific columns/rows to users
3. **Simplification:** Complex queries appear simple to end users
4. **Abstraction:** Hide table structure changes from applications

***

## Part 6: Views - Question 1 from PPT

### Problem Statement
Create a view that displays the order_id, customer_name, shipping_date, shipping_method, and shipping_status for all orders. Then query the view to retrieve all orders for 'Riya Nair' with 'Pending' shipping status.

### Step-by-Step Approach

**Step 1:** Join orders, customers, and shipping tables  
**Step 2:** Create a view with the required columns  
**Step 3:** Query the view with filters

### Solution with Detailed Explanation

**Creating the View:**
```sql
CREATE VIEW OrderShippingDetails AS
SELECT 
    o.order_id, 
    c.name AS customer_name, 
    s.shipping_date, 
    s.shipping_method, 
    s.shipping_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN shipping s ON o.order_id = s.order_id;
```

**Understanding the View Creation:**
- **CREATE VIEW OrderShippingDetails:** Names and creates the view
- **JOIN customers:** Get customer names
- **JOIN shipping:** Get shipping details
- All three tables are linked through **order_id** and **customer_id**

**Querying the View (First Time):**
```sql
SELECT order_id, customer_name, shipping_date, 
       shipping_method, shipping_status
FROM OrderShippingDetails
WHERE customer_name = 'Riya Nair' 
  AND shipping_status = 'Pending';
```

**Querying the View (Other Uses):**

Get all pending orders regardless of customer:
```sql
SELECT * FROM OrderShippingDetails
WHERE shipping_status = 'Pending';
```

Count orders by shipping status:
```sql
SELECT shipping_status, COUNT(*) AS total_orders
FROM OrderShippingDetails
GROUP BY shipping_status;
```

### Why This is Powerful

Once you create this view, you can query it like a regular table in any application or report without rewriting the complex joins every time!

***

## Part 7: Views - Question 2 from PPT

### Problem Statement
Create a view that tracks monthly revenue generated by each product. Then use it to find the top 5 products by revenue for January 2024.

### Step-by-Step Approach

**Step 1:** Join products, order_items, and orders tables  
**Step 2:** Calculate monthly revenue for each product  
**Step 3:** Create a view with the aggregated data  
**Step 4:** Query the view for specific month

### Solution with Detailed Explanation

**Creating the View:**
```sql
CREATE VIEW MonthlyProductRevenue AS
SELECT 
    p.product_id,
    p.name AS product_name,
    DATE_FORMAT(o.order_date, '%Y-%m') AS revenue_month,
    SUM(oi.subtotal) AS total_monthly_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_id, p.name, revenue_month;
```

**Breaking Down the View:**
- **DATE_FORMAT(o.order_date, '%Y-%m'):** Converts date to 'YYYY-MM' format (e.g., '2024-01')
- **SUM(oi.subtotal):** Totals all revenue for each product per month
- **GROUP BY:** Ensures one row per product-per-month combination

**Querying the View:**
```sql
SELECT *
FROM MonthlyProductRevenue
WHERE revenue_month = '2024-01'
ORDER BY total_monthly_revenue DESC
LIMIT 5;
```

**Other Useful Queries on This View:**

Top products across all time:
```sql
SELECT product_name, SUM(total_monthly_revenue) AS total_revenue
FROM MonthlyProductRevenue
GROUP BY product_name
ORDER BY total_revenue DESC;
```

Specific product revenue over time:
```sql
SELECT revenue_month, total_monthly_revenue
FROM MonthlyProductRevenue
WHERE product_name = 'Laptop'
ORDER BY revenue_month;
```

***

## Part 8: CTE vs Views Comparison

| Aspect | CTE | View |
|--------|-----|------|
| **Lifetime** | Temporary (only during query execution) | Persistent (stored in DB until dropped) |
| **Reusability** | Not reusable across queries | Reusable across multiple queries |
| **Storage** | Not stored in DB schema | Stored as named object in schema |
| **Use Case** | Break down one complex query | Simplify frequently used queries |
| **Syntax** | `WITH cte_name AS (...)` | `CREATE VIEW view_name AS ...` |
| **Best For** | One-off analysis, multi-step logic | Team use, security, DRY principle |
| **Performance** | Evaluated at runtime | Can be optimized based on usage |

***

## When to Use What?

**Use CTE when:**
- Working with a single complex query that needs breaking down
- You don't need the result outside this query
- You want temporary, readable intermediate steps
- Writing one-off analysis or reports

**Use View when:**
- Multiple queries need the same logic
- You want to restrict data access for security
- You're building reusable components for an application
- You want to simplify complex table structures for end users

***

## Summary

- **CTEs** help you write cleaner, more readable queries by breaking complex logic into named steps
- **Views** are stored queries that act like virtual tables for reuse across your application
- CTEs are temporary; Views are permanent
- Both simplify SQL and improve maintainability
- Choose based on scope: CTE for single queries, View for multiple queries

[1](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/131462429/c09a02de-2d42-4625-8e0d-313bfbcb89d2/Lecture-14.pdf)
