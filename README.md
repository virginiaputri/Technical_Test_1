# Technical_Test_1
**USER BEHAVIOR ANALYSIS**

**TECHNICAL TEST 1**

**Virginia Putri Annisa – Data Analyst**

**Overview**

This comprehensive analysis system processes and analyzes credit card transaction data, user demographics, and card information to provide insights into customer behavior, risk assessment, and spending patterns. The system is designed to run in Google Colab and leverages DuckDB for efficient data processing with robust error handling and comprehensive visualizations.

**Prerequisites**

1. Python 3.8+
2. Required libraries: Pandas, Matplotlib, Seaborn, DuckDB, Nbuatkanumpy
3. Database connection via duckdb to access tables:

- users_clean – cleaned user demographic and financial data
- cards_clean – cleaned credit card information
- transactions_clean – cleaned transaction data

1. Output directory (output_dir) must exist to save CSVs and visualizations.

**Features**

1. **Data Loading & Cleaning**
2. **Customer Profiling & Segmentation**
3. **Credit Card Analysis**
4. **Transaction Behavior Analysis**
5. **Visualization**
6. **Setup and Installation**
7. **from** google**.**colab **import** drive
8. drive**.**mount**(**'/content/drive'**)**
9. **!**pip install duckdb pandas matplotlib seaborn **\--**quiet
10. **import** os
11. **import** duckdb
12. **import** pandas **as** pd
13. **import** matplotlib**.**pyplot **as** plt
14. **import** seaborn **as** sns
15. **import** numpy **as** np
16. **from** datetime **import** datetime
17. **_\# Setup plot style_**
18. sns**.**set_style**(**"whitegrid"**)**
19. plt**.**rcParams**.**update**({**
20. 'font.size'**:** 12**,**
21. 'axes.labelsize'**:** 14**,**
22. 'axes.titlesize'**:** 16**,**
23. 'xtick.labelsize'**:** 12**,**
24. 'ytick.labelsize'**:** 12
25. **})**
26. palette **\=** sns**.**color_palette**(**"Set2"**)**
27. **Data Sources**

The project uses three CSV files:

- 1. transactions_data.csv: Transaction details per client and card.
  2. users_data.csv: Customer demographics, income, debt, and credit info.
  3. cards_data.csv: Credit card metadata.

Data is loaded into DuckDB for efficient in-memory SQL operations:

con **\=** duckdb**.**connect**(**database**\=**":memory:"**)**

con**.**execute**(**"""

CREATE TABLE transactions AS

SELECT \* FROM read_csv_auto('/content/drive/MyDrive/Technical Data Test 1/dataset/transactions_data.csv', ignore_errors=true);

"""**)**

con**.**execute**(**"""

CREATE TABLE users AS

SELECT \* FROM read_csv_auto('/content/drive/MyDrive/Technical Data Test 1/dataset/users_data.csv', ignore_errors=true);

"""**)**

con**.**execute**(**"""

CREATE TABLE cards AS

SELECT \* FROM read_csv_auto('/content/drive/MyDrive/Technical Data Test 1/dataset/cards_data.csv', ignore_errors=true);

"""**)**

1. **Data Cleaning Process**
    1. Transactions

The preprocessing steps include standardizing **id, client_id, and card_id**, parsing dates in multiple formats, converting **amount** to numeric with error handling, flagging invalid transactions, and transforming **use_chip** into a binary indicator.

CREATE OR REPLACE VIEW transactions_prep AS

SELECT

TRIM**(**CAST**(**id AS VARCHAR**))** AS id**,**

COALESCE**(**

TRY_CAST**(**date AS TIMESTAMP**),**

STRPTIME**(**CAST**(**date AS VARCHAR**),** '%Y-%m-%d %H:%M:%S'**),**

STRPTIME**(**CAST**(**date AS VARCHAR**),** '%Y-%m-%dT%H:%M:%S'**),**

STRPTIME**(**CAST**(**date AS VARCHAR**),** '%d/%m/%Y %H:%M:%S'**),**

STRPTIME**(**CAST**(**date AS VARCHAR**),** '%Y/%m/%d %H:%M:%S'**),**

STRPTIME**(**CAST**(**date AS VARCHAR**),** '%Y-%m-%d'**)**

**)** AS date_ts**,**

**...**

- 1. Users

The preprocessing steps include standardizing **yearly_income, total_debt, and per_capita_income**, handling non-numeric characters in financial fields, creating **income_segment** and **credit_segment**, and parsing **birth_date**.

CREATE OR REPLACE VIEW users_prep AS

SELECT

TRIM**(**CAST**(**id AS VARCHAR**))** AS id**,**

TRY_CAST**(**current_age AS INTEGER**)** AS current_age**,**

**...**

- 1. Cards

The preprocessing steps include extracting the **last four digits** of card numbers, parsing **expiration dates**, and converting flags such as **has_chip** and **card_on_dark_web** into numeric values.

CREATE OR REPLACE VIEW cards_prep AS

SELECT

TRIM**(**CAST**(**id AS VARCHAR**))** AS id**,**

**...**

1. Analysis Modules
    1. Customer Profiling and Segmentation

- Demographics & Economics

This step calculates user demographics, including gender, age, income, debt, credit score, and the number of credit cards.

**SELECT**

**COALESCE(**gender**,** 'unknown'**)** **as** gender**,**

**COUNT(\*)** **as** total_users**,**

**ROUND(AVG(**current_age**),** 1**)** **as** avg_age**,**

**ROUND(AVG(COALESCE(**yearly_income**,** 0**)),** 0**)** **as** avg_income**,**

**ROUND(AVG(COALESCE(**total_debt**,** 0**)),** 0**)** **as** avg_debt**,**

**ROUND(AVG(COALESCE(**credit_score**,** 0**)),** 0**)** **as** avg_credit_score**,**

**ROUND(AVG(COALESCE(**num_credit_cards**,** 0**)),** 1**)** **as** avg_cards

**FROM** users_clean

**GROUP** **BY** **COALESCE(**gender**,** 'unknown'**)**

**ORDER** **BY** total_users **DESC;**

- Financial Segmentation

Users are segmented based on income and debt levels:

| Segment | Description |
| --- | --- |
| High Income - Low Debt | Income > 100k, Debt < 50k |
| High Income - High Debt | Income > 100k, Debt >= 50k |
| Medium Income - Low Debt | 50k < Income <= 100k, Debt < 30k |
| Medium Income - High Debt | 50k &lt; Income <= 100k, Debt &gt;= 30k |
| Low Income - Low Debt | Income <= 50k, Debt < 20k |
| Low Income - High Debt | Income &lt;= 50k, Debt &gt;= 20k |

- Risk Analysis

The analysis measures the proportion of users who are near retirement, those with a high debt-to-income ratio (>40%), and those with poor credit scores (<600).

**Output:** user_risk_analysis.csv

user_risk_analysis **\=** con**.execute(**"""

SELECT

COUNT(\*) as total_users,

SUM(CASE WHEN current_age >= retirement_age - 5 THEN 1 ELSE 0 END) as near_retirement_count,

...

FROM users_clean

"""**).**df**()**

user_risk_analysis**.**to_csv**(**f'{output_dir}/user_risk_analysis.csv'**,** **index=False)**

- 1. Credit Card Analysis

The analysis examines the distribution of cards based on brand, type, chip presence, and dark web exposure. It measures the number of cards by brand and type, calculates the percentage of cards with chip technology, identifies the percentage of cards exposed on the dark web, and determines the average number of cards issued per customer. The results are saved in **card_distribution.csv**.

- Card Distribution

card_distribution **\=** con**.execute(**"""

SELECT

card_brand,

card_type,

COUNT(\*) as card_count,

...

FROM cards_clean

GROUP BY card_brand, card_type

ORDER BY card_count DESC

"""**).**df**()**

card_distribution**.**to_csv**(**f'{output_dir}/card_distribution.csv'**,** **index=False)**

- Risk Analysis

The analysis explores the relationship between users’ credit scores and the exposure of their cards on the dark web. The results are saved in **credit_score_darkweb_analysis.csv**.

risk_analysis **\=** con**.execute(**"""..."""**).**df**()**

risk_analysis**.**to_csv**(**f'{output_dir}/card_risk_analysis.csv'**,** **index=False)**

- 1. Transaction Behavior Analysis
- User Spending Behavior

The analysis examines customer transactions to measure the number of transactions, total spending, average transaction size, and the geographic and category diversity of spending. The results are saved in **transaction_behavior.csv**.

transaction_behavior **\=** con**.execute(**"""..."""**).**df**()**

transaction_behavior**.**to_csv**(**f'{output_dir}/transaction_behavior.csv'**,** **index=False)**

- Spending vs Income

The analysis compares users’ monthly spending to their monthly income and classifies them into three categories: **High Spenders** (spending more than 30% of income), **Moderate Spenders**, and **Low Spenders** (spending less than 10% of income). The results are saved in **spending_analysis.csv**.

payment_method_analysis **\=** con**.execute(**"""..."""**).**df**()**

payment_method_analysis**.**to_csv**(**f'{output_dir}/payment_method_analysis.csv'**,** **index=False)**

- Transaction Risk Analysis

The analysis measures **risk metrics per income segment**, including the number of large transactions (over $1000), failed transactions, the largest transaction, and the number of cities visited. The results are saved in **transaction_risk_analysis.csv**.

transaction_risk_analysis **\=** con**.execute(**"""..."""**).**df**()**

transaction_risk_analysis**.**to_csv**(**f'{output_dir}/transaction_risk_analysis.csv'**,** **index=False)**

1. Export All Data
2. dataframes **\=** **{**
3. 'user_demographics'**:** user_demographics**,**
4. 'user_segmentation'**:** user_segmentation**,**
5. 'user_risk_analysis'**:** user_risk_analysis**,**
6. 'card_distribution'**:** card_distribution**,**
7. **...**
8. **}**
9. **for** name**,** df **in** dataframes**.**items**():**
10. df**.**to_csv**(**f'{output_dir}/{name}.csv'**,** **index=False)**
11. con**.close()**

All CSVs are exported to output_dir, and all visualizations are saved under output_dir/visualizations.
