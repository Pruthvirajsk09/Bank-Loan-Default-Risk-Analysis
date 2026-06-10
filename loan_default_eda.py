"""
Bank Loan Default Risk Analysis
Author: Pruthviraj Kadam
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

plt.rcParams.update({'figure.facecolor':'#F8F9FA','axes.facecolor':'#FFFFFF',
    'axes.spines.top':False,'axes.spines.right':False,'font.family':'DejaVu Sans'})

df = pd.read_csv('data/loan_data.csv')
print(f"Dataset: {len(df):,} loans | Default Rate: {df['Default'].mean():.1%}")

fig, axes = plt.subplots(2, 3, figsize=(18, 11))
fig.suptitle('Loan Default Risk Analysis — BFSI Dashboard', fontsize=16, fontweight='bold')
fig.patch.set_facecolor('#F0F4F8')

# 1: Default rate by credit score band
ax = axes[0,0]
bins = [300,500,600,700,750,900]
labels = ['<500','500-599','600-699','700-749','750+']
df['CreditBand'] = pd.cut(df['CreditScore'], bins=bins, labels=labels)
cb = df.groupby('CreditBand', observed=True)['Default'].mean().mul(100)
colors = ['#E63946','#F4A261','#E9C46A','#90BE6D','#2A9D8F']
bars = ax.bar(cb.index, cb.values, color=colors, edgecolor='white', width=0.65)
for bar, val in zip(bars, cb.values):
    ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.4,
            f'{val:.1f}%', ha='center', fontsize=10, fontweight='bold')
ax.set_ylabel('Default Rate (%)'); ax.set_title('Default Rate by Credit Score Band', fontweight='bold')

# 2: Employment type
ax = axes[0,1]
emp = df.groupby('EmploymentType')['Default'].mean().mul(100).sort_values(ascending=False)
colors_e = ['#E63946' if v>30 else '#457B9D' for v in emp.values]
bars = ax.bar(emp.index, emp.values, color=colors_e, edgecolor='white', width=0.55)
for bar, val in zip(bars, emp.values):
    ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.4,
            f'{val:.1f}%', ha='center', fontsize=10, fontweight='bold')
ax.set_ylabel('Default Rate (%)'); ax.set_title('Default Rate by Employment Type', fontweight='bold')
plt.setp(ax.get_xticklabels(), rotation=15, ha='right')

# 3: Loan purpose
ax = axes[0,2]
purp = df.groupby('LoanPurpose')['Default'].mean().mul(100).sort_values(ascending=True)
ax.barh(purp.index, purp.values, color='#457B9D', edgecolor='white', height=0.55)
ax.axvline(df['Default'].mean()*100, color='red', linestyle='--', alpha=0.6, label='Avg')
for i, val in enumerate(purp.values):
    ax.text(val+0.3, i, f'{val:.1f}%', va='center', fontsize=9, fontweight='bold')
ax.set_xlabel('Default Rate (%)'); ax.set_title('Default Rate by Loan Purpose', fontweight='bold')
ax.legend(frameon=False)

# 4: Credit score distribution
ax = axes[1,0]
ax.hist(df[df['Default']==0]['CreditScore'], bins=30, alpha=0.7, color='#2A9D8F', label='Non-Default', edgecolor='white')
ax.hist(df[df['Default']==1]['CreditScore'], bins=30, alpha=0.7, color='#E63946', label='Default', edgecolor='white')
ax.set_xlabel('Credit Score'); ax.set_ylabel('Count')
ax.set_title('Credit Score: Default vs Non-Default', fontweight='bold')
ax.legend(frameon=False)

# 5: Loan-to-income heatmap
ax = axes[1,1]
df['LTI_Band'] = pd.cut(df['LoanToIncomeRatio'], bins=[-0.1,1,2,3,50],
                          labels=['Low (≤1x)','Moderate (1-2x)','High (2-3x)','Very High (>3x)'])
pivot = df.groupby(['CreditBand','LTI_Band'], observed=True)['Default'].mean().mul(100).unstack()
sns.heatmap(pivot, annot=True, fmt='.1f', cmap='RdYlGn_r', ax=ax,
            linewidths=0.5, cbar_kws={'label':'Default Rate %'})
ax.set_title('Default Rate — Credit Score × LTI Ratio', fontweight='bold')
plt.setp(ax.get_xticklabels(), rotation=20, ha='right', fontsize=8)

# 6: Risk category
ax = axes[1,2]
df['RiskScore'] = (
    ((df['CreditScore']<500)*5 + (df['CreditScore'].between(500,599))*3 + (df['CreditScore'].between(600,699))*1) +
    ((df['LoanToIncomeRatio']>3)*4 + (df['LoanToIncomeRatio'].between(2,3))*2 + (df['LoanToIncomeRatio'].between(1,2))*1) +
    ((df['EmploymentType']=='Unemployed')*4 + (df['EmploymentType']=='Self-Employed')*1) +
    ((df['ExistingLoans']>=4)*3 + (df['ExistingLoans'].between(2,3))*1)
)
df['RiskCat'] = pd.cut(df['RiskScore'], bins=[-1,2,5,8,20],
                        labels=['Low Risk','Medium Risk','High Risk','Critical Risk'])
rcat = df.groupby('RiskCat', observed=True)['Default'].mean().mul(100)
colors_r = ['#2A9D8F','#E9C46A','#F4A261','#E63946']
bars = ax.bar(rcat.index, rcat.values, color=colors_r, edgecolor='white', width=0.6)
for bar, val in zip(bars, rcat.values):
    ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.4,
            f'{val:.1f}%', ha='center', fontsize=11, fontweight='bold')
ax.set_ylabel('Default Rate (%)'); ax.set_title('Default Rate by Risk Category', fontweight='bold')

plt.tight_layout()
plt.savefig('docs/loan_dashboard.png', dpi=150, bbox_inches='tight', facecolor='#F0F4F8')
plt.close()
print("✅ Saved: docs/loan_dashboard.png")
print(f"\nNPA Exposure: ₹{df[df['Default']==1]['LoanAmount'].sum()/1e7:.1f} Crores")
print(f"Riskiest segment: Credit <500 + LTI >3x")
