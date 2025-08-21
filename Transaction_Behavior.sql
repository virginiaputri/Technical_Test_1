-- 3.1 Kebiasaan Belanja per Nasabah
WITH transaction_stats AS (
    SELECT
        t.client_id,
        COUNT(*) AS transaction_count,
        SUM(t.amount) AS total_spent,
        AVG(t.amount) AS avg_transaction_amount,
        MAX(t.amount) AS max_transaction_amount,
        COUNT(DISTINCT t.merchant_city) AS unique_cities,
        COUNT(DISTINCT t.mcc) AS unique_categories
    FROM transactions_clean t
    WHERE t.amount > 0
    GROUP BY t.client_id
)
SELECT
    u.yearly_income,
    u.credit_score,
    u.income_segment,
    COUNT(ts.client_id) AS user_count,
    ROUND(AVG(ts.transaction_count),1) AS avg_transactions,
    ROUND(AVG(ts.total_spent),0) AS avg_total_spent,
    ROUND(AVG(ts.avg_transaction_amount),2) AS avg_ticket_size,
    ROUND(AVG(ts.unique_cities),1) AS avg_unique_cities,
    ROUND(AVG(ts.unique_categories),1) AS avg_unique_categories
FROM transaction_stats ts
JOIN users_clean u ON ts.client_id = u.id
GROUP BY u.yearly_income, u.credit_score, u.income_segment
ORDER BY u.yearly_income DESC;


-- 3.2 Analisis Spending vs Income
WITH user_spending AS (
    SELECT
        t.client_id,
        SUM(t.amount) AS monthly_spending,
        COUNT(*) AS transaction_count
    FROM transactions_clean t
    WHERE MONTH(t.date_ts) = MONTH(CURRENT_DATE)
    GROUP BY t.client_id
)
SELECT
    u.id,
    u.yearly_income,
    u.yearly_income / 12 AS monthly_income,
    us.monthly_spending,
    us.transaction_count,
    CASE
        WHEN us.monthly_spending > (u.yearly_income / 12) * 0.3 THEN 'High Spender'
        WHEN us.monthly_spending < (u.yearly_income / 12) * 0.1 THEN 'Low Spender'
        ELSE 'Moderate Spender'
    END AS spending_behavior,
    ROUND((us.monthly_spending / (u.yearly_income / 12)) * 100,2) AS spending_to_income_ratio
FROM users_clean u
JOIN user_spending us ON u.id = us.client_id
WHERE u.yearly_income > 0;


-- 3.3 Analisis Metode Pembayaran
SELECT
    CASE
        WHEN use_chip_flag = 1 THEN 'Chip Transaction'
        WHEN use_chip_flag = 0 THEN 'Non-Chip Transaction'
        ELSE 'Unknown'
    END AS payment_method,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount),0) AS total_amount,
    ROUND(AVG(amount),2) AS avg_amount,
    ROUND(MAX(amount),2) AS max_amount
FROM transactions_clean
WHERE amount > 0
GROUP BY use_chip_flag
ORDER BY transaction_count DESC;


-- 3.4 Analisis Risiko Transaksi per Segmentasi Pendapatan
WITH user_transaction_stats AS (
    SELECT
        client_id,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN amount > 1000 THEN 1 ELSE 0 END) AS large_transactions,
        SUM(CASE WHEN has_error = 1 THEN 1 ELSE 0 END) AS failed_transactions,
        MAX(amount) AS largest_transaction,
        COUNT(DISTINCT merchant_city) AS cities_visited
    FROM transactions_clean
    GROUP BY client_id
)
SELECT
    u.income_segment,
    COUNT(*) AS user_count,
    ROUND(AVG(uts.total_transactions),1) AS avg_transactions,
    ROUND(AVG(uts.large_transactions),1) AS avg_large_transactions,
    ROUND(AVG(uts.failed_transactions),1) AS avg_failed_transactions,
    ROUND(AVG(uts.largest_transaction),0) AS avg_largest_transaction,
    ROUND(AVG(uts.cities_visited),1) AS avg_cities_visited
FROM user_transaction_stats uts
JOIN users_clean u ON uts.client_id = u.id
GROUP BY u.income_segment
ORDER BY user_count DESC;


-- 3.5 Trend Pengeluaran Bulanan
SELECT 
    YEAR(date_ts) AS year,
    MONTH(date_ts) AS month,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount
FROM transactions_clean
WHERE amount > 0
GROUP BY year, month
ORDER BY year, month;
