select * from employees;
select * from sales;

select e.employee_name, s.sale_amount from employees e
join
sales s
on e.employee_id = s.employee_id;

select e.employee_name, sum(s.sale_amount) from employees e
join
sales s
on e.employee_id = s.employee_id
GROUP BY 
e.employee_id, e.employee_name;

SELECT e.employee_name,
       (SELECT SUM(s.sale_amount)
        FROM sales s
        WHERE s.employee_id = e.employee_id) AS total_sales
FROM employees e;


WITH EmployeeSales AS (
    SELECT employee_id, SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY employee_id
)
SELECT e.employee_name, es.total_sales
FROM employees e
JOIN EmployeeSales es ON e.employee_id = es.employee_id;

-- Subquery Example
-- Find employees with total sales above 10,000 using subquery

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

-- Equivalent CTE Example
-- Using CTE to achieve the same result
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
