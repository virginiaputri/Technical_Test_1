-- 1. Clean Transactions Data (MySQL-compatible)
CREATE OR REPLACE VIEW transactions_prep AS
SELECT
    TRIM(CAST(id AS CHAR)) AS id,
    COALESCE(
        STR_TO_DATE(date, '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(date, '%Y-%m-%dT%H:%i:%s'),
        STR_TO_DATE(date, '%d/%m/%Y %H:%i:%s'),
        STR_TO_DATE(date, '%Y/%m/%d %H:%i:%s'),
        STR_TO_DATE(date, '%Y-%m-%d')
    ) AS date_ts,
    
    TRIM(CAST(client_id AS CHAR)) AS client_id,
    TRIM(CAST(card_id AS CHAR)) AS card_id,
    
    CAST(REPLACE(REPLACE(CAST(amount AS CHAR), ',', ''), '$', '') AS DECIMAL(18,2)) AS amount,
    
    CASE
        WHEN LOWER(TRIM(CAST(use_chip AS CHAR))) IN ('true','1','yes','y','t') THEN 1
        WHEN LOWER(TRIM(CAST(use_chip AS CHAR))) IN ('false','0','no','n') THEN 0
        ELSE NULL
    END AS use_chip_flag,
    
    TRIM(LOWER(CAST(merchant_id AS CHAR))) AS merchant_id,
    TRIM(LOWER(CAST(merchant_city AS CHAR))) AS merchant_city,
    TRIM(LOWER(CAST(merchant_state AS CHAR))) AS merchant_state,
    
    TRIM(CAST(zip AS CHAR)) AS zip,
    TRIM(CAST(mcc AS CHAR)) AS mcc,
    
    NULLIF(TRIM(CAST(errors AS CHAR)), '') AS errors_raw,
    CAST(NULLIF(TRIM(CAST(errors AS CHAR)), '') AS SIGNED) AS errors_int,
    
    CASE
        WHEN CAST(NULLIF(TRIM(CAST(errors AS CHAR)), '') AS SIGNED) > 0 THEN 1
        ELSE 0
    END AS has_error
FROM transactions;

-- 2. Clean Users Data (MySQL-compatible)
CREATE OR REPLACE VIEW users_prep AS
SELECT
    TRIM(CAST(id AS CHAR)) AS id,
    CAST(current_age AS SIGNED) AS current_age,
    CAST(retirement_age AS SIGNED) AS retirement_age,
    CAST(birth_year AS SIGNED) AS birth_year,
    CAST(birth_month AS SIGNED) AS birth_month,
    LOWER(TRIM(CAST(gender AS CHAR))) AS gender,
    TRIM(CAST(address AS CHAR)) AS address,
    CAST(latitude AS DECIMAL(10,6)) AS latitude,
    CAST(longitude AS DECIMAL(10,6)) AS longitude,
    
    -- Clean numeric income columns
    CAST(REGEXP_REPLACE(CAST(yearly_income AS CHAR), '[^0-9.]', '') AS DECIMAL(18,2)) AS yearly_income,
    CAST(REGEXP_REPLACE(CAST(total_debt AS CHAR), '[^0-9.]', '') AS DECIMAL(18,2)) AS total_debt,
    CAST(REGEXP_REPLACE(CAST(per_capita_income AS CHAR), '[^0-9.]', '') AS DECIMAL(18,2)) AS per_capita_income,
    
    CAST(credit_score AS SIGNED) AS credit_score,
    CAST(num_credit_cards AS SIGNED) AS num_credit_cards,
    
    -- Income segmentation
    CASE
        WHEN CAST(REGEXP_REPLACE(CAST(yearly_income AS CHAR), '[^0-9.]', '') AS DECIMAL(18,2)) < 50000 THEN 'Low Income'
        WHEN CAST(REGEXP_REPLACE(CAST(yearly_income AS CHAR), '[^0-9.]', '') AS DECIMAL(18,2)) BETWEEN 50000 AND 100000 THEN 'Medium Income'
        WHEN CAST(REGEXP_REPLACE(CAST(yearly_income AS CHAR), '[^0-9.]', '') AS DECIMAL(18,2)) > 100000 THEN 'High Income'
        ELSE 'Unknown Income'
    END AS income_segment,
    
    -- Credit score segmentation
    CASE
        WHEN CAST(credit_score AS SIGNED) < 600 THEN 'Poor'
        WHEN CAST(credit_score AS SIGNED) BETWEEN 600 AND 699 THEN 'Fair'
        WHEN CAST(credit_score AS SIGNED) BETWEEN 700 AND 799 THEN 'Good'
        WHEN CAST(credit_score AS SIGNED) >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS credit_segment,
    
    STR_TO_DATE(CONCAT('01/', birth_month, '/', birth_year), '%d/%m/%Y') AS birth_date
FROM users;

-- 3. Clean Cards Data
CREATE OR REPLACE VIEW cards_prep AS
SELECT
    TRIM(CAST(id AS CHAR)) AS id,
    TRIM(CAST(client_id AS CHAR)) AS client_id,
    
    LOWER(TRIM(CAST(card_brand AS CHAR))) AS card_brand,
    LOWER(TRIM(CAST(card_type AS CHAR))) AS card_type,
    
    CASE
        WHEN LENGTH(TRIM(CAST(card_number AS CHAR))) >= 4
        THEN RIGHT(TRIM(CAST(card_number AS CHAR)), 4)
        ELSE NULL
    END AS card_number_last4,
    
    TRIM(CAST(expires AS CHAR)) AS expires_raw,
    
    CASE
        WHEN expires LIKE '%/%' AND LENGTH(expires) = 7 THEN
            LAST_DAY(STR_TO_DATE(expires, '%m/%Y'))
        ELSE CAST(expires AS DATE)
    END AS expires_ts,
    
    CAST(cvv AS SIGNED) AS cvv,
    
    CASE
        WHEN LOWER(TRIM(CAST(has_chip AS CHAR))) IN ('true','1','yes') THEN 1
        WHEN LOWER(TRIM(CAST(has_chip AS CHAR))) IN ('false','0','no') THEN 0
        ELSE NULL
    END AS has_chip_flag,
    
    CAST(num_cards_issued AS SIGNED) AS num_cards_issued,
    CAST(REPLACE(CAST(credit_limit AS CHAR), ',', '') AS DECIMAL(18,2)) AS credit_limit,
    CAST(acct_open_date AS DATE) AS acct_open_ts,
    
    CASE
        WHEN LOWER(TRIM(CAST(card_on_dark_web AS CHAR))) IN ('true','1','yes','y') THEN 1
        ELSE 0
    END AS card_on_dark_web_flag
FROM cards;

-- 4. Create Final Clean Tables
CREATE TABLE IF NOT EXISTS transactions_clean AS 
SELECT * FROM transactions_prep;

CREATE TABLE IF NOT EXISTS users_clean AS 
SELECT * FROM users_prep;

CREATE TABLE IF NOT EXISTS cards_clean AS 
SELECT * FROM cards_prep;
