# User Behavior Analysis

## Overview

This project processes and analyzes credit card transactions, customer demographics, and card information to provide insights into **customer behavior, risk assessment, and spending patterns**.
It is designed to run in **Google Colab** and uses **DuckDB** for efficient data processing, with robust error handling and visualizations.

---

## Prerequisites

* **Python 3.8+**
* Required libraries:
  `pandas`, `numpy`, `matplotlib`, `seaborn`, `duckdb`
* Database connection via DuckDB with the following tables:

  * `users_clean` → cleaned user demographic and financial data
  * `cards_clean` → cleaned credit card information
  * `transactions_clean` → cleaned transaction data
* An **output directory (`output_dir`)** must exist to save CSVs and visualizations.

---

## Features

* **Data Loading & Cleaning**
* **Customer Profiling & Segmentation**
* **Credit Card Analysis**
* **Transaction Behavior Analysis**
* **Risk Assessment & Visualization**

---

## Setup and Installation

```python
from google.colab import drive
drive.mount('/content/drive')

!pip install duckdb pandas matplotlib seaborn --quiet

import os
import duckdb
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from datetime import datetime

# Setup plot style
sns.set_style("whitegrid")
plt.rcParams.update({
    'font.size': 12,
    'axes.labelsize': 14,
    'axes.titlesize': 16,
    'xtick.labelsize': 12,
    'ytick.labelsize': 12
})
palette = sns.color_palette("Set2")
```

---

## Data Sources

The project uses three CSV files:

* **transactions\_data.csv** → transaction details per client and card
* **users\_data.csv** → customer demographics, income, debt, and credit info
* **cards\_data.csv** → credit card metadata

These are loaded into DuckDB for in-memory SQL operations:

```sql
CREATE TABLE transactions AS
SELECT * FROM read_csv_auto('/content/drive/MyDrive/.../transactions_data.csv', ignore_errors=true);

CREATE TABLE users AS
SELECT * FROM read_csv_auto('/content/drive/MyDrive/.../users_data.csv', ignore_errors=true);

CREATE TABLE cards AS
SELECT * FROM read_csv_auto('/content/drive/MyDrive/.../cards_data.csv', ignore_errors=true);
```

---

## Data Cleaning Process

### Transactions

* Standardize `id`, `client_id`, and `card_id`
* Parse dates with multiple formats
* Convert `amount` to numeric with error handling
* Flag invalid transactions
* Convert `use_chip` to a binary indicator

### Users

* Standardize `yearly_income`, `total_debt`, and `per_capita_income`
* Handle non-numeric characters in financial fields
* Create `income_segment` and `credit_segment`
* Parse `birth_date`

### Cards

* Extract last four digits of card numbers
* Parse expiration dates
* Convert flags (`has_chip`, `card_on_dark_web`) to numeric

---

## Analysis Modules

### 1. Customer Profiling & Segmentation

* **Demographics & Economics** → distribution by gender, age, income, debt, credit score, and credit cards.
* **Financial Segmentation** → groups users by income and debt level:

  * High / Medium / Low Income × High / Low Debt
* **Risk Analysis** → measures proportion of users:

  * Near retirement
  * With debt-to-income ratio > 40%
  * With poor credit score (<600)
* **Output:** `user_demographics.csv`, `user_segmentation.csv`, `user_risk_analysis.csv`

---

### 2. Credit Card Analysis

* **Distribution** → by brand, type, chip presence, dark web exposure
* **Metrics:** number of cards, % with chip, % exposed on dark web, avg. cards per user
* **Risk Analysis** → credit score vs dark web exposure
* **Output:** `card_distribution.csv`, `credit_score_darkweb_analysis.csv`, `card_risk_analysis.csv`

---

### 3. Transaction Behavior Analysis

* **User Spending Behavior** → number of transactions, total spending, avg. transaction, geographic/category diversity

  * Output: `transaction_behavior.csv`
* **Spending vs Income** → classify users as High, Moderate, or Low Spenders

  * Output: `spending_analysis.csv`
* **Payment Methods** → chip vs non-chip transactions

  * Output: `payment_method_analysis.csv`
* **Risk Metrics by Income Segment** → large transactions, failed transactions, largest transaction, cities visited

  * Output: `transaction_risk_analysis.csv`

---

## Export Results

All analysis results are exported to CSV and saved in `output_dir`.
Visualizations are stored under `output_dir/visualizations/`.

```python
for name, df in dataframes.items():
    df.to_csv(f'{output_dir}/{name}.csv', index=False)

con.close()
```

---

With this pipeline, you can generate **customer insights, card risk metrics, and transaction behavior trends** in a reproducible way.

---

Kamu mau aku tambahin **contoh gambar visualisasi** (misalnya pie chart atau bar chart kecil) ke README biar lebih menarik, atau biarkan teks aja biar simpel?
