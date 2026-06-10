# 🏦 Bank Loan Default Risk Analysis

**Tools:** SQL (MySQL) · Python · Power BI  
**Domain:** BFSI — Banking & Financial Services  
**Dataset:** 3,000 loan records · 14 attributes  
**Author:** Pruthviraj Kadam  
🔗 [LinkedIn](https://www.linkedin.com/in/pruthviraj-kadam-patil/) | [GitHub](https://github.com/Pruthvirajsk09)

---

## 📌 Problem Statement

A lending institution is facing rising NPA (Non-Performing Assets) due to loan defaults. The risk team needs to identify which borrower segments are most likely to default, quantify the NPA exposure, and build a risk scoring model to flag high-risk applications before approval.

---

## 🎯 Business Objectives

| # | Business Question | Tool Used |
|---|---|---|
| 1 | What is our overall default rate and NPA exposure? | SQL + Power BI KPI Card |
| 2 | Which credit score band has highest default rate? | SQL CASE WHEN + Bar Chart |
| 3 | Does employment type affect default risk? | SQL GROUP BY + Python |
| 4 | Which loan purpose is riskiest? | SQL + Power BI Bar Chart |
| 5 | Can we score each borrower's risk before approving? | SQL CTE Risk Model |

---

## 📊 Key Findings

| Insight | Finding |
|---|---|
| Overall Default Rate | 36.5% — 1,095 out of 3,000 loans |
| Total NPA Exposure | ₹292.6 Crores |
| Riskiest Credit Band | Below 500 credit score — 55%+ default rate |
| Safest Credit Band | 750+ credit score — 8% default rate |
| Riskiest Employment | Unemployed borrowers — highest default rate |
| Riskiest Loan Purpose | Personal loans — highest default rate |
| Critical Risk Group | High LTI + Low Credit Score segment |

---

## 🗂️ Project Structure

```
loan-default-risk-analysis/
│
├── data/
│   └── loan_data.csv              ← 3,000 loan records
│
├── sql/
│   └── loan_default_analysis.sql  ← 15+ SQL queries
│
├── loan_default_eda.ipynb         ← Python EDA + visualizations
│
├── docs/
│   ├── loan_dashboard.png         ← Python dashboard
│   ├── powerbi_page1.png          ← Power BI Page 1
│   ├── powerbi_page2.png          ← Power BI Page 2
│   └── powerbi_page3.png          ← Power BI Page 3
│
└── README.md
```

---

## 🛠️ Tool 1 — SQL (MySQL)

**Sections covered:**
- Portfolio overview — total loans, NPA, default rate
- Credit score band analysis
- NPA exposure by risk tier — Subprime / Near-Prime / Prime
- Employment type and income analysis
- Loan-to-income ratio risk bands
- Loan purpose analysis
- Multi-factor risk scoring model using CTE
- Window function — RANK loans by risk within each purpose

**Key query — Risk Scoring Model using CTE:**
```sql
WITH risk_model AS (
    SELECT LoanID, EmploymentType, CreditScore,
           LoanAmount, LoanToIncomeRatio,
           ExistingLoans, Default_Flag,
        (
            CASE WHEN CreditScore < 500  THEN 5
                 WHEN CreditScore < 600  THEN 3
                 WHEN CreditScore < 700  THEN 1
                 ELSE 0 END +
            CASE WHEN LoanToIncomeRatio > 3  THEN 4
                 WHEN LoanToIncomeRatio > 2  THEN 2
                 WHEN LoanToIncomeRatio > 1  THEN 1
                 ELSE 0 END +
            CASE WHEN EmploymentType = 'Unemployed'    THEN 4
                 WHEN EmploymentType = 'Self-Employed' THEN 1
                 ELSE 0 END +
            CASE WHEN ExistingLoans >= 4 THEN 3
                 WHEN ExistingLoans >= 2 THEN 1
                 ELSE 0 END
        ) AS risk_score
    FROM loan_data
)
SELECT *,
    CASE
        WHEN risk_score >= 9  THEN 'Critical Risk'
        WHEN risk_score >= 6  THEN 'High Risk'
        WHEN risk_score >= 3  THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM risk_model
ORDER BY risk_score DESC;
```

**Why weighted scoring?** Credit score gets higher weight (max 5) than existing loans (max 3) because credit score is the strongest predictor of default — backed by both domain knowledge and our own data analysis showing 55% default rate for sub-500 scores.

---

## 🐍 Tool 2 — Python

**Libraries:** Pandas, NumPy, Matplotlib, Seaborn

```python
import pandas as pd
df = pd.read_csv('data/loan_data.csv')

print(f"Total Loans  : {len(df):,}")
print(f"Default Rate : {df['Default'].mean():.1%}")
print(f"NPA Exposure : ₹{df[df['Default']==1]['LoanAmount'].sum()/1e7:.1f} Crores")

# Default rate by credit score band
import pandas as pd
bins = [300, 500, 600, 700, 750, 900]
labels = ['<500','500-599','600-699','700-749','750+']
df['CreditBand'] = pd.cut(df['CreditScore'], bins=bins, labels=labels)
df.groupby('CreditBand', observed=True)['Default'].mean().mul(100)

# Employment type impact
df.groupby('EmploymentType')['Default'].mean().mul(100).sort_values(ascending=False)
```

**6 Charts generated:**
1. Default rate by credit score band
2. Default rate by employment type
3. Default rate by loan purpose
4. Credit score distribution — default vs non-default
5. Credit score × LTI ratio heatmap
6. Risk category validation chart

### Python Dashboard Preview
![Loan Dashboard](docs/loan_dashboard.png)

---

## 📊 Tool 3 — Power BI

**Power Query columns added:**
- `CreditBand` — Very Poor / Poor / Fair / Good / Excellent
- `LTI_Band` — Low / Moderate / High / Very High
- `RiskCategory` — Low / Medium / High / Critical
- `DefaultFlag` — 1/0 for calculations

**DAX Measures:**
```dax
Total Loans = COUNTROWS(loan_data)

Default Rate % =
DIVIDE(
    CALCULATE(COUNTROWS(loan_data), loan_data[Default_Flag] = 1),
    COUNTROWS(loan_data), 0
) * 100

NPA Exposure =
CALCULATE(SUM(loan_data[LoanAmount]), loan_data[Default_Flag] = 1)

Critical Risk Count =
CALCULATE(
    COUNTROWS(loan_data),
    loan_data[RiskCategory] = "Critical Risk"
)
```

**Page 1 — Portfolio Overview**
- KPI Cards: Total Loans, Default Rate %, NPA Exposure, Avg Loan Amount
- Bar chart: Default rate by Credit Score Band
- Bar chart: Default rate by Employment Type
- Slicers: LoanPurpose, City, EmploymentType

**Page 2 — Risk Analysis**
- Matrix: Credit Band × LTI Band — default rate heatmap with conditional formatting
- Bar chart: Default rate by loan purpose
- Bar chart: Risk category distribution
- Line chart: Default rate trend by loan amount

**Page 3 — Borrower Risk Tracker**
- Table: Individual loan records with risk category and default flag
- KPI Card: Critical Risk loan count
- KPI Card: Total NPA in critical risk group
- Recommendation text box

---

## 💡 Business Recommendations

1. **Tighten subprime lending** — Borrowers with credit score below 500 default at 55%+. Consider requiring collateral or co-signer for this segment.
2. **LTI ratio cap** — Loans with LTI ratio above 3× have significantly higher default. Implement a hard cap at 3× annual income.
3. **Employment verification** — Unemployed borrowers show highest default rate. Mandatory income proof and employment verification before approval.
4. **Proactive monitoring** — 244 loans flagged as Critical Risk. Assign relationship managers to these accounts for early intervention.

---

## 🚀 How to Run

```bash
git clone https://github.com/Pruthvirajsk09/loan-default-risk-analysis
pip install pandas numpy matplotlib seaborn
python loan_default_eda.py
```

---

## 📬 Connect

**Pruthviraj Kadam** | 📧 pruthvirajkadam009@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/pruthviraj-kadam-patil/) | [GitHub](https://github.com/Pruthvirajsk09)
