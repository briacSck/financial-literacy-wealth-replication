# Financial Literacy and Wealth: A Replication Study

**Replication of Table 3 from Lusardi & Mitchell (2023)**  
*ECON 140: Econometrics, UC Berkeley*  
**Author:** Briac Sockalingum  
**Date:** Spring 2024

[![Stata](https://img.shields.io/badge/Stata-17-blue)](https://www.stata.com/)
[![R](https://img.shields.io/badge/R-4.0+-green)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Overview

This project replicates and extends **Table 3** from Lusardi and Mitchell's (2023) *Journal of Economic Perspectives* paper, ["The Importance of Financial Literacy: Opening a New Field"](https://pubs.aeaweb.org/doi/pdfplus/10.1257/jep.37.4.137). Using the Survey of Consumer Finances (SCF) 2019 data, I estimate the relationship between financial literacy (measured by the "Big Three" financial literacy questions) and various household wealth outcomes.

## Research Question

**How does financial literacy relate to household wealth accumulation?**

The analysis examines whether individuals who correctly answer all three financial literacy questions (compound interest, inflation, and risk diversification) have systematically different wealth profiles, controlling for demographic and socioeconomic factors.

## Key Findings

- **Financial literacy shows robust positive associations with wealth measures** across specifications
- One additional correct answer on the financial literacy index is associated with **13% higher median net worth** (p < 0.001)
- Effects are strongest for **financial assets** (24% increase) compared to non-financial assets (7% increase)
- The wealth-to-income ratio increases by **15%** for each additional correct answer
- Results hold across both **weighted quantile regressions** and OLS specifications

## Data

**Source:** [Federal Reserve Survey of Consumer Finances (SCF) 2019](https://www.federalreserve.gov/econres/scfindex.htm)

### Required Data Files:
- `rscfp2019.dta` - Summary extract data
- `p19i6.dta` - Full public data file  
- `p19_rw1.dta` - Replicate weights

**Sample:** 5,777 U.S. households (nationally representative)

### Key Variables:
- **Financial Literacy:** Big Three questions (compound interest, inflation, risk diversification)
- **Wealth Measures:** Net worth, financial assets, non-financial assets, wealth-to-income ratio
- **Controls:** Age, gender, race/ethnicity, education, marital status, employment, income

## Repository Structure
```
financial-literacy-wealth-replication/
├── code/
│   ├── 01_main_analysis.do      # Stata: data prep + regressions
│   └── 02_quantile_reg.R        # R alternative implementation
├── data/                         # User downloads SCF data here
├── output/
│   └── tables/                  # Regression output
├── docs/
│   └── Lusardi_Mitchell_2023.pdf
├── README.md
└── requirements.txt
```

## Methodology

### Data Processing
1. **Merging:** Combined three SCF datasets (summary, weights, public files)
2. **Winsorization:** Trimmed outliers at 5th/95th percentiles for wealth/income variables
3. **Variable Construction:**  
   - Created `finlit_3c` binary indicator (1 if all Big Three correct)
   - Generated demographic dummies (race, education, marital status, employment)
   - Rescaled wealth variables to $100,000 units

### Empirical Specification

Wealth_i = β₀ + β₁FinLit_i + β₂Age_i + β₃Female_i + β₄Race_i + β₅Education_i + β₆Marital_i + β₇Employment_i + β₈Income_i + ε_i

**Estimation Methods:**
- **Median (quantile) regressions** with robust standard errors
- **Weighted** by SCF survey weights (`x42001`)
- Controls: Age, gender, race, education, marital status, employment, income
