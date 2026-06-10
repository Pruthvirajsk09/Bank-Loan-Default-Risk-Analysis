-- ============================================================
-- BANK LOAN DEFAULT RISK ANALYSIS
-- Author: Pruthviraj Kadam
-- Dataset: 3,000 loan records | BFSI Domain
-- ============================================================

CREATE TABLE loan_data (
    LoanID              VARCHAR(10) PRIMARY KEY,
    Age                 INT,
    EmploymentType      VARCHAR(20),
    EmploymentYears     INT,
    City                VARCHAR(10),
    MonthlyIncome       INT,
    LoanAmount          INT,
    LoanPurpose         VARCHAR(20),
    LoanTenureMonths    INT,
    InterestRate        DECIMAL(5,2),
    ExistingLoans       INT,
    CreditScore         INT,
    LoanToIncomeRatio   DECIMAL(6,3),
    Default_Flag        INT
);

-- ============================================================
-- SECTION 1: PORTFOLIO OVERVIEW
-- ============================================================

SELECT
    COUNT(*)                              AS total_loans,
    ROUND(SUM(LoanAmount)/1e7, 2)        AS total_portfolio_crores,
    SUM(Default_Flag)                     AS total_defaults,
    ROUND(AVG(Default_Flag)*100, 2)      AS default_rate_pct,
    ROUND(AVG(CreditScore), 0)           AS avg_credit_score,
    ROUND(AVG(LoanAmount), 0)            AS avg_loan_amount,
    ROUND(AVG(InterestRate), 2)          AS avg_interest_rate,
    ROUND(SUM(CASE WHEN Default_Flag=1 THEN LoanAmount ELSE 0 END)/1e7,2) AS npa_crores
FROM loan_data;

-- ============================================================
-- SECTION 2: CREDIT SCORE ANALYSIS
-- ============================================================

-- 2.1 Default rate by credit score band
SELECT
    CASE
        WHEN CreditScore < 500 THEN 'Very Poor (<500)'
        WHEN CreditScore < 600 THEN 'Poor (500-599)'
        WHEN CreditScore < 700 THEN 'Fair (600-699)'
        WHEN CreditScore < 750 THEN 'Good (700-749)'
        ELSE 'Excellent (750+)'
    END AS credit_band,
    COUNT(*) AS total_loans,
    SUM(Default_Flag) AS defaults,
    ROUND(AVG(Default_Flag)*100, 2) AS default_rate_pct,
    ROUND(AVG(InterestRate), 2) AS avg_interest_rate,
    ROUND(AVG(LoanAmount), 0)   AS avg_loan_amount
FROM loan_data
GROUP BY credit_band
ORDER BY default_rate_pct DESC;

-- 2.2 NPA exposure by credit band
SELECT
    CASE
        WHEN CreditScore < 600 THEN 'Subprime (<600)'
        WHEN CreditScore < 700 THEN 'Near-Prime (600-699)'
        ELSE 'Prime (700+)'
    END AS risk_tier,
    COUNT(*) AS loans,
    ROUND(SUM(LoanAmount)/1e6, 2) AS total_exposure_M,
    ROUND(SUM(CASE WHEN Default_Flag=1 THEN LoanAmount ELSE 0 END)/1e6, 2) AS npa_M,
    ROUND(AVG(Default_Flag)*100, 2) AS default_rate_pct
FROM loan_data
GROUP BY risk_tier
ORDER BY default_rate_pct DESC;

-- ============================================================
-- SECTION 3: EMPLOYMENT & INCOME ANALYSIS
-- ============================================================

-- 3.1 Default by employment type
SELECT
    EmploymentType,
    COUNT(*) AS total,
    SUM(Default_Flag) AS defaults,
    ROUND(AVG(Default_Flag)*100, 2) AS default_rate_pct,
    ROUND(AVG(MonthlyIncome), 0) AS avg_income,
    ROUND(AVG(LoanAmount), 0)   AS avg_loan
FROM loan_data
GROUP BY EmploymentType
ORDER BY default_rate_pct DESC;

-- 3.2 Loan-to-income ratio risk
SELECT
    CASE
        WHEN LoanToIncomeRatio <= 1   THEN 'Low (<=1x)'
        WHEN LoanToIncomeRatio <= 2   THEN 'Moderate (1-2x)'
        WHEN LoanToIncomeRatio <= 3   THEN 'High (2-3x)'
        ELSE 'Very High (>3x)'
    END AS lti_band,
    COUNT(*) AS loans,
    ROUND(AVG(Default_Flag)*100, 2) AS default_rate_pct,
    ROUND(AVG(CreditScore), 0)      AS avg_credit_score
FROM loan_data
GROUP BY lti_band
ORDER BY default_rate_pct DESC;

-- ============================================================
-- SECTION 4: LOAN PURPOSE ANALYSIS
-- ============================================================

SELECT
    LoanPurpose,
    COUNT(*) AS total_loans,
    SUM(Default_Flag) AS defaults,
    ROUND(AVG(Default_Flag)*100, 2) AS default_rate_pct,
    ROUND(AVG(LoanAmount), 0)       AS avg_loan_amount,
    ROUND(AVG(InterestRate), 2)     AS avg_interest_rate,
    ROUND(SUM(CASE WHEN Default_Flag=1 THEN LoanAmount ELSE 0 END)/1e6, 2) AS npa_M
FROM loan_data
GROUP BY LoanPurpose
ORDER BY default_rate_pct DESC;

-- ============================================================
-- SECTION 5: ADVANCED — RISK SCORING MODEL
-- ============================================================

-- 5.1 Multi-factor risk score using CTE
WITH risk_model AS (
    SELECT
        LoanID, Age, EmploymentType, CreditScore,
        MonthlyIncome, LoanAmount, LoanPurpose,
        LoanToIncomeRatio, ExistingLoans, Default_Flag,
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
                 ELSE 0 END +
            CASE WHEN EmploymentYears < 1 THEN 2
                 WHEN EmploymentYears < 3 THEN 1
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

-- 5.2 Risk category summary with default validation
WITH risk_model AS (
    SELECT LoanID, LoanAmount, Default_Flag,
        (CASE WHEN CreditScore < 500 THEN 5 WHEN CreditScore < 600 THEN 3 WHEN CreditScore < 700 THEN 1 ELSE 0 END +
         CASE WHEN LoanToIncomeRatio > 3 THEN 4 WHEN LoanToIncomeRatio > 2 THEN 2 WHEN LoanToIncomeRatio > 1 THEN 1 ELSE 0 END +
         CASE WHEN EmploymentType='Unemployed' THEN 4 WHEN EmploymentType='Self-Employed' THEN 1 ELSE 0 END +
         CASE WHEN ExistingLoans >= 4 THEN 3 WHEN ExistingLoans >= 2 THEN 1 ELSE 0 END
        ) AS risk_score
    FROM loan_data
),
categorized AS (
    SELECT *,
        CASE WHEN risk_score >= 9 THEN 'Critical' WHEN risk_score >= 6 THEN 'High'
             WHEN risk_score >= 3 THEN 'Medium' ELSE 'Low' END AS risk_category
    FROM risk_model
)
SELECT risk_category,
    COUNT(*) AS loans,
    ROUND(AVG(Default_Flag)*100, 2) AS actual_default_rate_pct,
    ROUND(SUM(LoanAmount)/1e6, 2)   AS exposure_M,
    ROUND(SUM(CASE WHEN Default_Flag=1 THEN LoanAmount ELSE 0 END)/1e6, 2) AS npa_M
FROM categorized
GROUP BY risk_category
ORDER BY actual_default_rate_pct DESC;

-- 5.3 Window function: Rank loans by default risk within each purpose
WITH scored AS (
    SELECT LoanID, LoanPurpose, CreditScore, LoanAmount,
           LoanToIncomeRatio, Default_Flag,
           RANK() OVER (PARTITION BY LoanPurpose ORDER BY CreditScore ASC, LoanToIncomeRatio DESC) AS risk_rank
    FROM loan_data
)
SELECT * FROM scored
WHERE risk_rank <= 5
ORDER BY LoanPurpose, risk_rank;
