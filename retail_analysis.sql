USE Business_Context;


-- EDA

SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_Id) AS unique_customers
FROM Customer;

SELECT
    COUNT(*) AS product_rows,
    COUNT(DISTINCT prod_cat_code) AS categories,
    COUNT(DISTINCT prod_subcat_code) AS subcategories
FROM prod_cat_info;

SELECT
    COUNT(*) AS transaction_rows,
    COUNT(DISTINCT transaction_id) AS unique_transactions,
    COUNT(DISTINCT cust_id) AS unique_customers,
    MIN(tran_date) AS first_transaction,
    MAX(tran_date) AS last_transaction
FROM Transactions;

SELECT
    MIN(Qty) AS min_quantity,
    MAX(Qty) AS max_quantity,
    AVG(Qty) AS avg_quantity,
    MIN(total_amt) AS min_amount,
    MAX(total_amt) AS max_amount,
    AVG(total_amt) AS avg_amount,
    SUM(total_amt) AS net_revenue
FROM Transactions;

SELECT
    Gender,
    COUNT(*) AS customer_count
FROM Customer
GROUP BY Gender
ORDER BY customer_count DESC;

SELECT
    city_code,
    COUNT(*) AS customer_count
FROM Customer
GROUP BY city_code
ORDER BY customer_count DESC;

SELECT
    store_type,
    COUNT(*) AS transaction_count,
    SUM(Qty) AS quantity_sold,
    SUM(total_amt) AS net_revenue
FROM Transactions
GROUP BY store_type
ORDER BY net_revenue DESC;

SELECT
    CASE
        WHEN total_amt < 0 THEN 'Return'
        ELSE 'Sale'
    END AS transaction_type,
    COUNT(*) AS transaction_count,
    SUM(ABS(total_amt)) AS transaction_value
FROM Transactions
GROUP BY
    CASE
        WHEN total_amt < 0 THEN 'Return'
        ELSE 'Sale'
    END;

SELECT
    p.prod_cat,
    COUNT(*) AS transaction_count,
    SUM(t.Qty) AS quantity_sold,
    SUM(t.total_amt) AS net_revenue
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
GROUP BY p.prod_cat
ORDER BY net_revenue DESC;

SELECT
    YEAR(tran_date) AS transaction_year,
    MONTH(tran_date) AS transaction_month,
    COUNT(*) AS transaction_count,
    SUM(Qty) AS quantity_sold,
    SUM(total_amt) AS net_revenue
FROM Transactions
GROUP BY YEAR(tran_date), MONTH(tran_date)
ORDER BY transaction_year, transaction_month;


-- Data Quality

SELECT COUNT(*) AS missing_customer_ids
FROM Customer
WHERE customer_Id IS NULL;

SELECT COUNT(*) AS missing_gender
FROM Customer
WHERE Gender IS NULL;

SELECT COUNT(*) AS missing_city_codes
FROM Customer
WHERE city_code IS NULL;

SELECT COUNT(*) AS missing_transaction_customer_ids
FROM Transactions
WHERE cust_id IS NULL;

SELECT COUNT(*) AS missing_transaction_dates
FROM Transactions
WHERE tran_date IS NULL;

SELECT COUNT(*) AS missing_product_codes
FROM Transactions
WHERE prod_cat_code IS NULL
   OR prod_subcat_code IS NULL;

SELECT COUNT(*) AS duplicate_customer_ids
FROM (
    SELECT customer_Id
    FROM Customer
    GROUP BY customer_Id
    HAVING COUNT(*) > 1
) x;

SELECT COUNT(*) AS duplicate_transaction_ids
FROM (
    SELECT transaction_id
    FROM Transactions
    GROUP BY transaction_id
    HAVING COUNT(*) > 1
) x;


-- Customer Analysis

SELECT
    Gender,
    COUNT(*) AS customer_count
FROM Customer
WHERE Gender IN ('M', 'F')
GROUP BY Gender;

SELECT
    city_code,
    COUNT(*) AS customer_count
FROM Customer
GROUP BY city_code
ORDER BY customer_count DESC
LIMIT 10;

SELECT
    cust_id,
    COUNT(*) AS transaction_count
FROM Transactions
WHERE total_amt >= 0
GROUP BY cust_id
HAVING COUNT(*) > 10
ORDER BY transaction_count DESC;

SELECT
    c.customer_Id,
    SUM(t.total_amt) AS total_revenue
FROM Transactions t
INNER JOIN Customer c
    ON t.cust_id = c.customer_Id
WHERE TIMESTAMPDIFF(
          YEAR,
          c.DOB,
          (SELECT MAX(tran_date) FROM Transactions)
      ) BETWEEN 25 AND 35
AND t.tran_date BETWEEN
    DATE_SUB(
        (SELECT MAX(tran_date) FROM Transactions),
        INTERVAL 30 DAY
    )
    AND (SELECT MAX(tran_date) FROM Transactions)
GROUP BY c.customer_Id
ORDER BY total_revenue DESC;


-- Product Analysis

SELECT
    p.prod_cat,
    COUNT(DISTINCT p.prod_subcat_code) AS subcategory_count,
    SUM(t.Qty) AS quantity_sold,
    SUM(t.total_amt) AS net_revenue
FROM prod_cat_info p
INNER JOIN Transactions t
    ON p.prod_cat_code = t.prod_cat_code
    AND p.prod_subcat_code = t.prod_subcat_code
GROUP BY p.prod_cat
ORDER BY net_revenue DESC;

SELECT
    p.prod_subcat,
    SUM(t.Qty) AS quantity_sold,
    SUM(t.total_amt) AS net_revenue
FROM prod_cat_info p
INNER JOIN Transactions t
    ON p.prod_cat_code = t.prod_cat_code
    AND p.prod_subcat_code = t.prod_subcat_code
GROUP BY p.prod_subcat
ORDER BY net_revenue DESC
LIMIT 10;

SELECT
    p.prod_cat,
    SUM(t.total_amt) AS total_revenue
FROM prod_cat_info p
INNER JOIN Transactions t
    ON p.prod_cat_code = t.prod_cat_code
    AND p.prod_subcat_code = t.prod_subcat_code
WHERE p.prod_cat IN ('Electronics', 'Books')
GROUP BY p.prod_cat;

SELECT
    p.prod_cat,
    p.prod_subcat,
    SUM(t.total_amt) AS male_revenue
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
INNER JOIN Customer c
    ON t.cust_id = c.customer_Id
WHERE p.prod_cat = 'Electronics'
  AND c.Gender = 'M'
GROUP BY p.prod_cat, p.prod_subcat
ORDER BY male_revenue DESC;


-- Sales Analysis

SELECT
    SUM(total_amt) AS net_revenue
FROM Transactions;

SELECT
    store_type,
    SUM(total_amt) AS total_revenue
FROM Transactions
GROUP BY store_type
ORDER BY total_revenue DESC;

SELECT
    p.prod_cat,
    SUM(t.total_amt) AS revenue
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
WHERE p.prod_cat IN ('Electronics', 'Clothing')
  AND t.store_type = 'Flagship store'
GROUP BY p.prod_cat;

SELECT
    p.prod_cat,
    AVG(t.total_amt) AS average_transaction_value
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
GROUP BY p.prod_cat
HAVING AVG(t.total_amt) >
       (SELECT AVG(total_amt) FROM Transactions);

WITH TopCategories AS (
    SELECT
        p.prod_cat
    FROM Transactions t
    INNER JOIN prod_cat_info p
        ON t.prod_cat_code = p.prod_cat_code
        AND t.prod_subcat_code = p.prod_subcat_code
    GROUP BY p.prod_cat
    ORDER BY SUM(t.Qty) DESC
    LIMIT 5
)
SELECT
    p.prod_cat,
    p.prod_subcat,
    AVG(t.total_amt) AS average_revenue,
    SUM(t.total_amt) AS total_revenue,
    SUM(t.Qty) AS total_quantity_sold
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
INNER JOIN TopCategories tc
    ON p.prod_cat = tc.prod_cat
GROUP BY p.prod_cat, p.prod_subcat
ORDER BY total_revenue DESC;


-- Return Analysis

SELECT
    COUNT(*) AS returned_transactions,
    SUM(ABS(total_amt)) AS return_value
FROM Transactions
WHERE total_amt < 0;

SELECT
    p.prod_cat,
    COUNT(*) AS return_transactions,
    SUM(ABS(t.total_amt)) AS return_value
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
WHERE t.total_amt < 0
GROUP BY p.prod_cat
ORDER BY return_value DESC;

SELECT
    p.prod_subcat,
    COUNT(*) AS return_transactions,
    SUM(ABS(t.total_amt)) AS return_value
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
WHERE t.total_amt < 0
GROUP BY p.prod_subcat
ORDER BY return_value DESC
LIMIT 10;

SELECT
    p.prod_cat,
    SUM(ABS(t.total_amt)) AS return_value
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
WHERE t.total_amt < 0
AND t.tran_date BETWEEN
    DATE_SUB(
        (SELECT MAX(tran_date) FROM Transactions),
        INTERVAL 3 MONTH
    )
    AND (SELECT MAX(tran_date) FROM Transactions)
GROUP BY p.prod_cat
ORDER BY return_value DESC
LIMIT 1;


-- Store Analysis

SELECT
    store_type,
    SUM(total_amt) AS total_revenue
FROM Transactions
GROUP BY store_type
ORDER BY total_revenue DESC;

SELECT
    store_type,
    SUM(Qty) AS total_quantity_sold
FROM Transactions
GROUP BY store_type
ORDER BY total_quantity_sold DESC;

SELECT
    store_type,
    COUNT(*) AS transaction_count
FROM Transactions
GROUP BY store_type
ORDER BY transaction_count DESC;


-- Time Analysis

SELECT
    YEAR(tran_date) AS transaction_year,
    MONTH(tran_date) AS transaction_month,
    COUNT(*) AS transaction_count,
    SUM(Qty) AS quantity_sold,
    SUM(total_amt) AS net_revenue
FROM Transactions
GROUP BY YEAR(tran_date), MONTH(tran_date)
ORDER BY transaction_year, transaction_month;

SELECT
    YEAR(tran_date) AS transaction_year,
    SUM(total_amt) AS net_revenue
FROM Transactions
GROUP BY YEAR(tran_date)
ORDER BY transaction_year;

SELECT
    YEAR(tran_date) AS transaction_year,
    COUNT(*) AS return_transactions,
    SUM(ABS(total_amt)) AS return_value
FROM Transactions
WHERE total_amt < 0
GROUP BY YEAR(tran_date)
ORDER BY transaction_year;


-- Business Analysis

SELECT
    p.prod_subcat,
    SUM(CASE WHEN t.total_amt >= 0 THEN t.total_amt ELSE 0 END) AS sales_value,
    COUNT(CASE WHEN t.total_amt < 0 THEN 1 END) AS return_transactions,
    SUM(CASE WHEN t.total_amt < 0 THEN ABS(t.total_amt) ELSE 0 END) AS return_value
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
GROUP BY p.prod_subcat
ORDER BY sales_value DESC
LIMIT 5;

SELECT
    store_type,
    SUM(total_amt) AS revenue,
    SUM(Qty) AS quantity_sold
FROM Transactions
GROUP BY store_type
ORDER BY revenue DESC;

SELECT
    p.prod_cat,
    SUM(t.Qty) AS quantity_sold,
    SUM(t.total_amt) AS revenue
FROM Transactions t
INNER JOIN prod_cat_info p
    ON t.prod_cat_code = p.prod_cat_code
    AND t.prod_subcat_code = p.prod_subcat_code
GROUP BY p.prod_cat
ORDER BY quantity_sold DESC;