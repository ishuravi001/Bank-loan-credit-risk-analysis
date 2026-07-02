"""
Bank Loan / Credit Risk Analysis - Data Cleaning & EDA
Step 1 of the end-to-end project pipeline.
"""

import pandas as pd
import numpy as np

# ---------------------------------------------------------
# 1. LOAD RAW DATA
# ---------------------------------------------------------
df = pd.read_csv('/home/claude/credit_risk_project/loan_data_raw.csv')
print(f"Raw shape: {df.shape}")

# ---------------------------------------------------------
# 2. REMOVE DUPLICATES
# ---------------------------------------------------------
dupes_removed = df.duplicated().sum()
df = df.drop_duplicates()
print(f"Removed {dupes_removed} duplicate rows")

# ---------------------------------------------------------
# 3. STANDARDIZE TEXT FIELDS (fix inconsistent casing)
# ---------------------------------------------------------
df['home_ownership'] = df['home_ownership'].str.upper()
df['purpose'] = df['purpose'].str.lower().str.strip()
df['addr_state'] = df['addr_state'].str.upper()

# ---------------------------------------------------------
# 4. HANDLE MISSING VALUES
# ---------------------------------------------------------
# emp_length: missing -> treat as "Unknown" category (don't assume tenure)
df['emp_length'] = df['emp_length'].fillna('Unknown')

# annual_inc: missing -> impute with median income WITHIN the same loan grade
# (income correlates with grade, so this is more accurate than a global median)
df['annual_inc'] = df.groupby('grade')['annual_inc'].transform(
    lambda x: x.fillna(x.median())
)

# revol_util: missing -> impute with median (small % missing, low variance impact)
df['revol_util'] = df['revol_util'].fillna(df['revol_util'].median())

print("Missing values after cleaning:")
print(df.isnull().sum()[df.isnull().sum() > 0] if df.isnull().sum().sum() > 0 else "None")

# ---------------------------------------------------------
# 5. FEATURE ENGINEERING
# ---------------------------------------------------------

# Binary target: is_default (1 = Charged Off or Late, 0 = Fully Paid/Current)
df['is_default'] = df['loan_status'].isin(['Charged Off', 'Late (31-120 days)']).astype(int)

# DTI risk bucket
def dti_bucket(dti):
    if dti < 10:
        return 'Low (<10%)'
    elif dti < 20:
        return 'Moderate (10-20%)'
    elif dti < 30:
        return 'High (20-30%)'
    else:
        return 'Very High (30%+)'

df['dti_bucket'] = df['dti'].apply(dti_bucket)

# Income bracket
def income_bracket(inc):
    if inc < 40000:
        return 'Low (<40k)'
    elif inc < 70000:
        return 'Lower-Middle (40-70k)'
    elif inc < 100000:
        return 'Upper-Middle (70-100k)'
    else:
        return 'High (100k+)'

df['income_bracket'] = df['annual_inc'].apply(income_bracket)

# Loan-to-income ratio (loan amount relative to annual income)
df['loan_to_income'] = round(df['loan_amnt'] / df['annual_inc'], 3)

# Risk tier based on grade (business-friendly grouping)
risk_tier_map = {'A': 'Low Risk', 'B': 'Low Risk', 'C': 'Medium Risk',
                  'D': 'Medium Risk', 'E': 'High Risk', 'F': 'High Risk', 'G': 'High Risk'}
df['risk_tier'] = df['grade'].map(risk_tier_map)

# Clean term to numeric months
df['term_months'] = df['term'].str.extract(r'(\d+)').astype(int)

# ---------------------------------------------------------
# 6. QUICK EDA SUMMARY (printed for sanity check / report)
# ---------------------------------------------------------
print("\n--- Default rate by grade ---")
print(df.groupby('grade')['is_default'].mean().round(3).sort_index())

print("\n--- Default rate by DTI bucket ---")
print(df.groupby('dti_bucket')['is_default'].mean().round(3))

print("\n--- Default rate by purpose ---")
print(df.groupby('purpose')['is_default'].mean().round(3).sort_values(ascending=False))

print("\n--- Default rate by income bracket ---")
print(df.groupby('income_bracket')['is_default'].mean().round(3))

print("\n--- Overall default rate ---")
print(round(df['is_default'].mean(), 3))

# ---------------------------------------------------------
# 7. SAVE CLEANED DATA
# ---------------------------------------------------------
df.to_csv('/home/claude/credit_risk_project/loan_data_cleaned.csv', index=False)
print(f"\nCleaned shape: {df.shape}")
print("Saved to loan_data_cleaned.csv")
