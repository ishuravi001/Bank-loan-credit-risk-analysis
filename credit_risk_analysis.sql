-- ============================================================
-- BANK LOAN / CREDIT RISK ANALYSIS - SQL SCHEMA & QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 1. SCHEMA: Create table to load the cleaned dataset
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS credit_risk_db;
USE credit_risk_db;

DROP TABLE IF EXISTS loans;

CREATE TABLE loans (
    loan_id            INT PRIMARY KEY,
    loan_amnt          INT,
    term                VARCHAR(15),
    term_months         INT,
    int_rate            DECIMAL(5,2),
    installment         DECIMAL(10,2),
    grade               VARCHAR(2),
    sub_grade           VARCHAR(3),
    emp_length          VARCHAR(15),
    home_ownership      VARCHAR(15),
    annual_inc          DECIMAL(12,2),
    income_bracket      VARCHAR(30),
    purpose             VARCHAR(30),
    addr_state          VARCHAR(2),
    dti                 DECIMAL(5,2),
    dti_bucket          VARCHAR(25),
    delinq_2yrs         INT,
    inq_last_6mths      INT,
    open_acc            INT,
    pub_rec             INT,
    revol_util          DECIMAL(5,2),
    total_acc           INT,
    loan_to_income      DECIMAL(6,3),
    risk_tier           VARCHAR(15),
    issue_year          INT,
    issue_month         INT,
    loan_status         VARCHAR(25),
    is_default          TINYINT
);

-- Load data (adjust path for your MySQL server / LOCAL INFILE settings):
-- LOAD DATA LOCAL INFILE 'loan_data_cleaned.csv'
-- INTO TABLE loans
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;


-- ============================================================
-- 2. BUSINESS-QUESTION QUERIES
-- ============================================================

-- Q1. Overall default rate and portfolio size
SELECT
    COUNT(*) AS total_loans,
    SUM(is_default) AS total_defaults,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct,
    ROUND(SUM(loan_amnt), 0) AS total_disbursed
FROM loans;


-- Q2. Default rate by loan grade (core risk driver)
SELECT
    grade,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct,
    ROUND(AVG(int_rate), 2) AS avg_int_rate
FROM loans
GROUP BY grade
ORDER BY grade;


-- Q3. Default rate by DTI bucket
SELECT
    dti_bucket,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY dti_bucket
ORDER BY FIELD(dti_bucket, 'Low (<10%)','Moderate (10-20%)','High (20-30%)','Very High (30%+)');


-- Q4. Default rate by loan purpose
SELECT
    purpose,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct,
    ROUND(AVG(loan_amnt), 0) AS avg_loan_amount
FROM loans
GROUP BY purpose
ORDER BY default_rate_pct DESC;


-- Q5. Default rate by income bracket
SELECT
    income_bracket,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY income_bracket
ORDER BY default_rate_pct DESC;


-- Q6. High-risk segment: combined grade + DTI + delinquency flag
-- (identifies applicants that should get the strictest underwriting review)
SELECT
    grade,
    dti_bucket,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loans
WHERE delinq_2yrs > 0
GROUP BY grade, dti_bucket
HAVING COUNT(*) >= 10
ORDER BY default_rate_pct DESC
LIMIT 10;


-- Q7. State-wise risk exposure (top 10 states by default rate, min 50 loans)
SELECT
    addr_state,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct,
    ROUND(SUM(loan_amnt), 0) AS total_disbursed
FROM loans
GROUP BY addr_state
HAVING COUNT(*) >= 50
ORDER BY default_rate_pct DESC
LIMIT 10;


-- Q8. Trend over time: default rate by issue year
SELECT
    issue_year,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY issue_year
ORDER BY issue_year;


-- Q9. Interest rate vs default outcome (does pricing match realized risk?)
SELECT
    grade,
    ROUND(AVG(int_rate), 2) AS avg_int_rate,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct,
    ROUND(AVG(int_rate) / NULLIF(AVG(is_default) * 100, 0), 3) AS rate_to_risk_ratio
FROM loans
GROUP BY grade
ORDER BY grade;


-- Q10. Employment length vs default rate (does tenure reduce risk?)
SELECT
    emp_length,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY emp_length
ORDER BY default_rate_pct DESC;


-- Q11. Loan-to-income ratio risk check
SELECT
    CASE
        WHEN loan_to_income < 0.15 THEN 'Low (<15%)'
        WHEN loan_to_income < 0.30 THEN 'Moderate (15-30%)'
        ELSE 'High (30%+)'
    END AS lti_bucket,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY lti_bucket
ORDER BY default_rate_pct DESC;


-- Q12. Home ownership vs default rate
SELECT
    home_ownership,
    COUNT(*) AS num_loans,
    ROUND(AVG(is_default) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY home_ownership
ORDER BY default_rate_pct DESC;
