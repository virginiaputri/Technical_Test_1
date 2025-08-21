-- 2.1 Distribusi Kartu
SELECT 
    card_brand,
    card_type,
    COUNT(*) AS card_count,
    ROUND(AVG(COALESCE(num_cards_issued, 0)), 1) AS avg_cards_issued,
    SUM(COALESCE(card_on_dark_web_flag, 0)) AS dark_web_cards,
    ROUND((SUM(COALESCE(card_on_dark_web_flag, 0)) * 100.0 / COUNT(*)), 2) AS pct_dark_web,
    SUM(CASE WHEN has_chip_flag = 1 THEN 1 ELSE 0 END) AS chip_cards,
    ROUND((SUM(CASE WHEN has_chip_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS pct_chip_cards
FROM cards_clean
WHERE card_brand IS NOT NULL AND card_type IS NOT NULL
GROUP BY card_brand, card_type
ORDER BY card_count DESC;

-- 2.2 Analisis Credit Score vs Kartu di Dark Web
SELECT 
    CASE 
        WHEN u.credit_score >= 750 THEN 'Excellent (750+)'
        WHEN u.credit_score >= 700 THEN 'Good (700-749)'
        WHEN u.credit_score >= 650 THEN 'Fair (650-699)'
        ELSE 'Poor (<650)'
    END AS credit_score_category,
    COUNT(c.id) AS total_cards,
    SUM(c.card_on_dark_web_flag) AS dark_web_cards,
    ROUND((SUM(c.card_on_dark_web_flag) * 100.0 / COUNT(c.id)), 2) AS pct_dark_web
FROM users_clean u
JOIN cards_clean c ON u.id = c.client_id
GROUP BY credit_score_category
HAVING COUNT(c.id) > 0
ORDER BY credit_score_category;

-- 2.3 Analisis Expiration Status Kartu
SELECT 
    card_brand,
    COUNT(*) AS total_cards,
    SUM(CASE WHEN expires_ts < CURRENT_DATE THEN 1 ELSE 0 END) AS expired_cards,
    SUM(CASE WHEN expires_ts BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 1 YEAR) THEN 1 ELSE 0 END) AS expiring_soon,
    SUM(CASE WHEN expires_ts > DATE_ADD(CURRENT_DATE, INTERVAL 1 YEAR) THEN 1 ELSE 0 END) AS valid_cards
FROM cards_clean
WHERE expires_ts IS NOT NULL
GROUP BY card_brand
ORDER BY total_cards DESC;

-- 2.4 Analisis Risiko Kartu
SELECT 
    c.card_brand,
    c.card_type,
    COUNT(*) AS total_cards,
    SUM(c.card_on_dark_web_flag) AS dark_web_cards,
    ROUND((SUM(c.card_on_dark_web_flag) * 100.0 / COUNT(*)), 2) AS pct_dark_web,
    ROUND(AVG(u.credit_score), 0) AS avg_credit_score,
    SUM(CASE WHEN u.credit_score < 650 THEN 1 ELSE 0 END) AS poor_credit_users,
    SUM(CASE WHEN c.has_chip_flag = 0 THEN 1 ELSE 0 END) AS no_chip_cards
FROM cards_clean c
JOIN users_clean u ON c.client_id = u.id
GROUP BY c.card_brand, c.card_type
HAVING COUNT(*) > 0
ORDER BY pct_dark_web DESC;

-- 2.5 Kartu tanpa Chip per Brand
SELECT 
    card_brand,
    SUM(CASE WHEN has_chip_flag = 0 THEN 1 ELSE 0 END) AS no_chip_cards,
    COUNT(*) AS total_cards,
    ROUND(SUM(CASE WHEN has_chip_flag = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_no_chip
FROM cards_clean
GROUP BY card_brand
ORDER BY pct_no_chip DESC;
