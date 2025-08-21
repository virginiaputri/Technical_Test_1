-- 1.1 Demografi
SELECT 
    COALESCE(gender, 'unknown') AS gender,
    COUNT(*) AS total_users,
    ROUND(AVG(current_age), 1) AS avg_age,
    ROUND(AVG(COALESCE(yearly_income, 0)), 0) AS avg_income,
    ROUND(AVG(COALESCE(total_debt, 0)), 0) AS avg_debt,
    ROUND(AVG(COALESCE(credit_score, 0)), 0) AS avg_credit_score,
    ROUND(AVG(COALESCE(num_credit_cards, 0)), 1) AS avg_cards
FROM users_clean
GROUP BY COALESCE(gender, 'unknown')
ORDER BY total_users DESC;

-- 1.2 Segmentasi Berdasarkan Kemampuan Finansial
WITH user_stats AS (
    SELECT 
        id,
        COALESCE(yearly_income, 0) AS yearly_income,
        COALESCE(total_debt, 0) AS total_debt,
        COALESCE(credit_score, 0) AS credit_score,
        current_age,
        retirement_age,
        CASE 
            WHEN COALESCE(yearly_income, 0) > 100000 AND COALESCE(total_debt, 0) < 50000 THEN 'High Income Low Debt'
            WHEN COALESCE(yearly_income, 0) > 100000 AND COALESCE(total_debt, 0) >= 50000 THEN 'High Income High Debt'
            WHEN COALESCE(yearly_income, 0) <= 50000 AND COALESCE(total_debt, 0) < 20000 THEN 'Low Income Low Debt'
            WHEN COALESCE(yearly_income, 0) <= 50000 AND COALESCE(total_debt, 0) >= 20000 THEN 'Low Income High Debt'
            WHEN COALESCE(yearly_income, 0) BETWEEN 50000 AND 100000 AND COALESCE(total_debt, 0) < 30000 THEN 'Medium Income Low Debt'
            WHEN COALESCE(yearly_income, 0) BETWEEN 50000 AND 100000 AND COALESCE(total_debt, 0) >= 30000 THEN 'Medium Income High Debt'
            ELSE 'Unknown Financial'
        END AS financial_segment,
        CASE 
            WHEN yearly_income > 0 THEN ROUND((total_debt / yearly_income) * 100, 2)
            ELSE 0 
        END AS debt_to_income_ratio,
        CASE 
            WHEN current_age >= retirement_age - 5 THEN 'Near Retirement'
            WHEN current_age <= 30 THEN 'Young Adult'
            WHEN current_age BETWEEN 31 AND 50 THEN 'Middle Age'
            ELSE 'Senior'
        END AS age_segment
    FROM users_clean
    WHERE yearly_income IS NOT NULL AND total_debt IS NOT NULL
)
SELECT 
    financial_segment,
    age_segment,
    COUNT(*) AS user_count,
    ROUND(AVG(yearly_income), 0) AS avg_income,
    ROUND(AVG(total_debt), 0) AS avg_debt,
    ROUND(AVG(debt_to_income_ratio), 2) AS avg_dti_ratio,
    ROUND(AVG(credit_score), 0) AS avg_credit_score
FROM user_stats
WHERE financial_segment != 'Unknown Financial'
GROUP BY financial_segment, age_segment
ORDER BY user_count DESC;

-- 1.3 Analisis Risiko
SELECT 
    COUNT(*) AS total_users,
    SUM(CASE WHEN current_age >= retirement_age - 5 THEN 1 ELSE 0 END) AS near_retirement_count,
    SUM(CASE WHEN yearly_income > 0 AND (total_debt / yearly_income) > 0.4 THEN 1 ELSE 0 END) AS high_dti_ratio_count,
    SUM(CASE WHEN credit_score < 600 THEN 1 ELSE 0 END) AS poor_credit_count,
    SUM(CASE WHEN num_credit_cards > 5 THEN 1 ELSE 0 END) AS many_cards_count,
    
    ROUND((SUM(CASE WHEN current_age >= retirement_age - 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS pct_near_retirement,
    ROUND((SUM(CASE WHEN yearly_income > 0 AND (total_debt / yearly_income) > 0.4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS pct_high_dti,
    ROUND((SUM(CASE WHEN credit_score < 600 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS pct_poor_credit
FROM users_clean;

-- 1.4 Income vs Debt Summary
SELECT
    COALESCE(gender, 'unknown') AS gender,
    ROUND(AVG(yearly_income), 0) AS avg_income,
    ROUND(AVG(total_debt), 0) AS avg_debt,
    ROUND(AVG(total_debt / NULLIF(yearly_income,0)), 2) AS avg_dti_ratio,
    COUNT(*) AS user_count
FROM users_clean
WHERE yearly_income IS NOT NULL AND total_debt IS NOT NULL AND yearly_income > 0
GROUP BY gender
ORDER BY user_count DESC;
