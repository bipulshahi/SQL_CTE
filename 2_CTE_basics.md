Let's start by explaining the differences between Common Table Expressions (CTEs) and Subqueries in MySQL, and which one might be better to use, followed by step-by-step beginner-friendly explanations with examples.

## Differences Between CTEs and Subqueries in MySQL

### What is a Subquery?
- A subquery is a query nested inside another query.
- It can appear in the SELECT, FROM, or WHERE clauses.
- It executes for each row processed by the outer query (if correlated), which can be inefficient.
- Subqueries can make SQL statements harder to read especially if nested deeply.

### What is a CTE (Common Table Expression)?
- A CTE is a temporary named result set defined within a SQL statement using the WITH clause.
- It can be referenced multiple times within the same query.
- It improves readability by breaking complex queries into simpler steps.
- CTEs exist only during the execution of the query and are not stored permanently.
- CTEs are easier to debug and maintain.

### Comparison: Which is Better?
| Aspect            | Subquery                           | CTE                                    |
|-------------------|----------------------------------|---------------------------------------|
| Readability       | Can become complex and nested    | Easier to read and understand         |
| Reusability       | Cannot reuse within the same query| Can be referenced multiple times      |
| Performance       | May be slower, especially correlated subqueries | Sometimes performs better due to optimizer hints |
| Modularity        | Limited                          | Great for breaking down steps         |
| Lifetime          | Temporary within the query        | Temporary within the query             |

In most cases, CTEs are preferred for complex queries due to their readability and modularity.

## Simple Examples

### Subquery Example
Find employees with total sales above 10,000 using subquery:
```sql
SELECT
    e.employee_name,
    (SELECT SUM(s.sale_amount)
     FROM sales s
     WHERE s.employee_id = e.employee_id
    ) AS total_sales
FROM
    employees e
WHERE
    (SELECT SUM(s.sale_amount)
     FROM sales s
     WHERE s.employee_id = e.employee_id
    ) > 10000;
```

### Equivalent CTE Example
Using CTE to achieve the same result:
```sql
WITH EmployeeSales AS (
    SELECT employee_id,
           SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY employee_id
)
SELECT e.employee_name,
       es.total_sales
FROM employees e
JOIN EmployeeSales es ON e.employee_id = es.employee_id
WHERE es.total_sales > 10000;
```

This CTE example is cleaner, easier to read, and allows you to reuse "EmployeeSales" if needed further in the query.

## Explanation of the Provided Data Structure

The database `ecommerce_db` contains tables related to an e-commerce system:
- Customers, Categories, Products
- Orders and Order Items
- Payments and Shipping
- Employees and Sales

These tables are linked by foreign keys, allowing queries that join multiple tables to extract meaningful insights.

With this setup, you can practice writing CTEs and views to analyze data step-by-step.

***

Next, I will explain a few example questions from the ppt, how to solve them using CTEs, and provide detailed explanations using your ecommerce data.

[1](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/131462429/c09a02de-2d42-4625-8e0d-313bfbcb89d2/Lecture-14.pdf)
