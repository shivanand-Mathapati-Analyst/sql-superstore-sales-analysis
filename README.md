<div align="center">

# 🗄️ Superstore Sales Analysis — SQL Server

### End-to-end T-SQL analysis diagnosing why sales grew every year while profit stagnated and declined

[![Tool](https://img.shields.io/badge/Tool-Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](#)
[![T-SQL](https://img.shields.io/badge/T--SQL-CTEs%20%7C%20Views%20%7C%20Window%20Functions-217346?style=for-the-badge)](#)
[![Analysis](https://img.shields.io/badge/Modules-9%20Analysis%20Areas-blue?style=for-the-badge)](#)
[![Dataset](https://img.shields.io/badge/Dataset-Superstore%20Kaggle-orange?style=for-the-badge)](#)
[![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)](#)

</div>

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Tech Stack](#️-tech-stack)
- [Script Structure](#-script-structure)
- [Data Validation](#-data-validation)
- [Repository Structure](#-repository-structure)
- [How to Use](#-how-to-use)
- [Business Problem](#-business-problem)
- [Key Insights (Summary)](#-key-insights-summary)
- [Root Cause Analysis](#-root-cause-analysis)
- [Actionable Recommendations](#-actionable-recommendations)
- [Author](#-author)
- [License](#-license)

---

## 📌 Overview

This project is an **end-to-end T-SQL analysis** of the classic **Sample Superstore** dataset (9,994 records, 2014–2017), built entirely in **Microsoft SQL Server**. It diagnoses a real business problem — strong sales growth paired with declining profitability — using CTEs, window functions, and reusable views across 9 structured analysis modules.

Every query in the script is followed by a plain-English insight comment, so the script reads like a guided analysis rather than a pile of disconnected queries — and closes with a full Business Problem → Key Insights → Root Causes → Recommendations writeup, the same way a real analytics deliverable would.

**This project is part of a three-tool analytics portfolio built on the same Superstore dataset.**

This project uses the same Superstore dataset as my [Excel](https://github.com/shivanand-Mathapati-Analyst/excel-superstore-sales-analysis) and [Power BI](https://github.com/shivanand-Mathapati-Analyst/powerbi-superstore-sales-analysis) projects, demonstrating how the same business problem can be analyzed and solved using three different analytics tools: SQL Server, Excel, and Power BI.

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| **Microsoft SQL Server** | Database engine, schema design, data storage |
| **T-SQL** | CTEs, Views, Window Functions (LAG, ROW_NUMBER, RANK, running totals), Subqueries |


---

## 📁 Script Structure

1. Database & Schema Setup
2. Data Validation (row counts, nulls, duplicates, invalid values) + Primary Key Constraint
3. Sales Analysis
4. Profit Analysis
5. Customer Analysis
6. Product Analysis
7. Geographical Analysis
8. Shipping & Operations Analysis
9. Discount Analysis
10. Time-Based Analysis
11. Key Insights (Summary)
12. Business Root Causes
13. Actionable Recommendations

---

## ✅ Data Validation

Before any analysis, the dataset is validated to confirm it's fit for business use:

- **Row count check** — confirms all 9,994 records loaded correctly
- **Duplicate check** — confirms `RowID` uniquely identifies every record
- **Null check** — across all key transactional columns (Sales, Profit, Discount, Quantity, dates, IDs)
- **Invalid value check** — negative sales/quantities, out-of-range discounts, ship dates earlier than order dates
- **Date range validation** — confirms the dataset spans January 2014 to December 2017 (Some shipdates upto January 2018)
- **Primary Key constraint** — `RowID` is enforced as the Primary Key on the working copy table

No data quality issues were found — the dataset is complete and suitable for sales, customer, product, profitability, and operational analysis.

---

## 📁 Repository Structure

```
sql-superstore-sales-analysis/
│
├── SQL-Sales-Analysis-Project-SQLServer.sql   # Full T-SQL script (setup → validation → 9 analysis modules → insights)
└── README.md
```

---

## 🚀 How to Use

1. Open `superstore-sql-analysis.sql` in **SQL Server Management Studio (SSMS)**
2. Import the Sample Superstore CSV into a table named `Sales.superstore` in a new database (the script creates the database and schema — you'll need to load the source CSV into the base table before running the validation/analysis sections)
3. Run the script section by section — each block is commented and independent, so you can execute one analysis module at a time

---

## 🧩 Business Problem

> Our company has experienced strong sales growth but declining profitability. Analyze the data and identify the root causes, key issues, and actionable recommendations.

---

## 📈 Key Insights (Summary)

- Sales grew every year, but **margin peaked in 2016 (13.4%) and declined in 2017 (12.7%)** despite a 20%+ sales increase — the core symptom behind the business problem
- **Discounts above 30% are margin-negative**, and discounts above 50% lose far more than the sale is worth (-119.2% margin)
- **The company gave away $322.58K in discounts** — more than the entire $286.82K in profit earned over the same period
- **Furniture — specifically Tables and Bookcases — is the only structurally unprofitable category**, despite receiving the highest average discount (17.4%) of any category
- **Texas, Ohio, Colorado, Illinois, and Pennsylvania** are the biggest loss contributors — Texas by sheer sales volume, Ohio and Colorado by consistently poor margins regardless of size
- **26.3% of all orders (1,318 of 5,009) are unprofitable**, indicating a systemic discounting/pricing issue rather than isolated bad deals
- **Copiers remain highly profitable (19.39% of total profit) despite low discounting (16.2%)**, proving that heavy discounts aren't required to drive strong sales
- The **top 20% of customers** contribute a disproportionately high share of total revenue (Pareto effect)
- **High sales don't always mean high profit** — the top customer by sales revenue ranked among the bottom 10 by profit
- **Seasonality is not the root cause** — Q4 posted the strongest sales and profit growth, ruling out demand as the underlying issue

---

## 🔍 Root Cause Analysis

### 🔴 Root Cause 1 — Discounting Is the Biggest Reason for Low Profit

- **Profit margins become negative when discounts exceed 30%**
- **1,020 orders (20.4% of all orders) received discounts above 30%** — meaning 1 in every 5 orders was sold at a heavily discounted price
- **The company gave away $322.58K in discounts** — more than the total profit of $286.82K earned in the same period
- **1,318 of 5,009 orders (26%) resulted in a loss**, and loss-making products climbed sharply with discount depth, with **380 loss-making products** in the 50%+ discount band alone
- **Products discounted 70–80% (e.g. Eureka Disposable at 80%) are almost universally loss-making**

### 🔴 Root Cause 2 — Furniture Has Low Profitability

- **Furniture received the highest average discount (17.4%) but contributed only 6.58% of total profit**, despite generating over $742K in sales
- **Technology received the lowest average discount (13.2%) and generated the highest profit contribution (50.71%)**
- **Tables generated high sales but resulted in an overall loss** due to heavy discounting
- **Copiers generated 19.39% of total profit with a relatively low discount (16.2%)**, showing that premium products remain highly profitable

### 🔴 Root Cause 3 — High Sales Don't Always Mean High Profit

- **Sean Miller was the top customer by sales ($25K)** but ranked among the **bottom 10 customers by profit**
- **Tamara Chand was the most profitable customer**, generating **$8.98K in profit**, despite not being among the top customers by sales

### 🔴 Root Cause 4 — Losses Are Concentrated in a Few States

- **10 of 49 states (~20%) are net loss-making**, with **Texas posting the largest state-level loss (-$25.73K)**
- **Ohio and Colorado had the lowest profit margins** (-21.69% and -20.33%)
- **The top 10 loss-making states generated $705.7K in sales but operated at a combined margin of -13.9%**
- **116 of 531 cities (22%) are loss-making**, led by **Philadelphia (-$13.84K)** — losses are broad-based, not isolated outliers

### 🔴 Root Cause 5 — Seasonality Is Not the Main Cause of Low Profits

- **Q4 generated the highest sales ($878K) and the strongest profit growth (53.23% QoQ)** — demand is strong, so seasonality isn't the main driver
- **December was the most profitable month ($43.79K)**, even though **November had the highest sales**
- **February recorded the lowest sales ($59.75K) but achieved the highest profit margin (17.23%)**

### 🔴 Root Cause 6 — A High Number of Orders Are Loss-Making

- **1,318 of 5,009 orders (26.3%) were loss-making** — more than 1 in every 4 orders generated a loss, indicating a recurring profitability issue rather than isolated cases

---

## ✅ Actionable Recommendations

| # | Recommendation | Root Cause Addressed |
|---|---|---|
| 1 | **Limit discounts above 30%** and require approval for higher discounts to protect profit margins | Discounting (Cause 1) |
| 2 | **Review products receiving very high discounts (50%+)**, as many of them are generating losses | Discounting (Cause 1) |
| 3 | **Reassess pricing and discount strategies for Furniture, especially Tables**, to improve category profitability | Furniture (Cause 2) |
| 4 | **Use Technology and Copiers as pricing benchmarks**, since they maintain strong profitability with lower discounts | Furniture (Cause 2) |
| 5 | **Focus on customer profitability in addition to sales revenue** when managing key customer accounts | Sales vs Profit (Cause 3) |
| 6 | **Conduct detailed margin reviews for Texas, Ohio, and Colorado** to identify the causes of persistent losses | Geographic Losses (Cause 4) |
| 7 | **Review pricing and discount policies in loss-making states and cities** to improve regional profitability | Geographic Losses (Cause 4) |
| 8 | **Prioritize improvements in pricing and discount management rather than seasonal promotions**, as demand remains strong throughout peak periods | Seasonality (Cause 5) |
| 9 | **Implement profit-margin checks before approving orders** to reduce the number of loss-making transactions | Loss-Making Orders (Cause 6) |

---

## 👤 Author

**Shivanand S Mathapati**

- 🌐 Portfolio: 
- ✉️ Email: 

---

## 📄 License

This project is licensed under the **MIT License** — feel free to use the SQL patterns and analysis structure for your own learning or portfolio projects. See [LICENSE](LICENSE) for details.

---

<div align="center">

⭐ **If you found this project useful, consider giving it a star!** ⭐

</div>
