********************************************************************************
* PROJECT: Financial Literacy and Wealth Accumulation
* PAPER:   Replication of Lusardi & Mitchell (2023), Table 3
* AUTHOR:  Briac Sockalingum
* COURSE:  ECON 140, UC Berkeley
* DATE:    Spring 2024
*
* PURPOSE: Replicate Table 3 median regressions showing relationship between
*          financial literacy (Big Three questions) and household wealth
*
* DATA:    Survey of Consumer Finances (SCF) 2019
*          https://www.federalreserve.gov/econres/scfindex.htm
*
* OUTPUT:  output/tables/table3_replication.tex
********************************************************************************

clear all
set more off
set maxvar 12000
set matsize 750

* Create log file
log using "output/logs/main_analysis.log", replace

********************************************************************************
* PART 1: LOAD AND MERGE DATASETS
********************************************************************************

* Load public data file (demographics, main weight)
use "data/p19i6.dta", clear

    * Lowercase all variable names
    foreach v of varlist _all {
       capture rename `v' `=lower("`v'")'
    }
    
    keep y1 x8023 x42001  // ID, marital status, weight
    tempfile public
    save `public'

* Load replicate weights  
use "data/p19_rw1.dta", clear

    foreach v of varlist _all {
       capture rename `v' `=lower("`v'")'
    }
    
    tempfile weights
    save `weights'

* Load summary extract (main analysis file)
use "data/rscfp2019.dta", clear

    foreach v of varlist _all {
       capture rename `v' `=lower("`v'")'
    }
    
    keep yy1 y1 wgt age hhsex edcl racecl4 occat1 kids ///
         finlit income networth asset fin nfin

* Merge datasets
merge m:1 yy1 using `weights', nogenerate
merge 1:1 y1 using `public', nogenerate

* Create implicate number (SCF has 5 multiply-imputed datasets)
gen implic = y1 - 10 * yy1
label var implic "Implicate number (1-5)"

********************************************************************************
* PART 2: DATA PREPARATION
********************************************************************************

*------------------------------------------------------------------------------
* 2.1 Winsorize wealth and income variables
*------------------------------------------------------------------------------

* Check if winsor2 installed
capture which winsor2
if _rc ssc install winsor2

* Summary before winsorization
di _n "*** Pre-Winsorization Summary (Implicate 1) ***"
sum networth asset fin nfin income if implic==1, detail

* Winsorize at 5th and 95th percentiles for each implicate
* (SCF uses multiple imputation to handle missing data)
forvalues i=1/5 {
    winsor2 networth asset fin nfin income if implic==`i', ///
        replace cuts(5 95)
}

* Summary after winsorization
di _n "*** Post-Winsorization Summary (Implicate 1) ***"
sum networth asset fin nfin income if implic==1, detail

*------------------------------------------------------------------------------
* 2.2 Create wealth-to-income ratio
*------------------------------------------------------------------------------

gen rwlth_incm = networth / income
label var rwlth_incm "Wealth-to-income ratio"

* Winsorize ratio variable
forvalues i=1/5 {
    winsor2 rwlth_incm if implic==`i', replace cuts(5 95)
}

*------------------------------------------------------------------------------
* 2.3 Create demographic variables
*------------------------------------------------------------------------------

** Gender
gen female = (hhsex == 2)
label var female "Female household head"

** Race/ethnicity (reference: White)
gen black = (racecl4 == 2)
gen hispanic = (racecl4 == 3)
gen raceoth = (racecl4 == 4)

label var black "Black non-Hispanic"
label var hispanic "Hispanic"
label var raceoth "Other race"

** Education (reference: College+)
gen ed_lshs = (edcl == 1)  // Less than high school
gen ed_hs = (edcl == 2)    // High school  
gen ed_sc = (edcl == 3)    // Some college

label var ed_lshs "Education: < High school"
label var ed_hs "Education: High school"
label var ed_sc "Education: Some college"

** Marital status (reference: Never married/Living with partner)
gen married = inlist(x8023, 1, 2)
gen widowed = (x8023 == 5)
gen ntmarried = (x8023 == 6)  // Divorced/separated

label var married "Married"
label var widowed "Widowed"  
label var ntmarried "Divorced/Separated"

** Employment (reference: Working for someone else)
gen slfemply = (occat1 == 2)  // Self-employed
gen rtrddsbl = (occat1 == 3)  // Retired/disabled/student
gen ntworkng = (occat1 == 4)  // Other not working

label var slfemply "Self-employed"
label var rtrddsbl "Retired/Disabled/Student"
label var ntworkng "Not working (other)"

*------------------------------------------------------------------------------
* 2.4 Financial literacy variables
*------------------------------------------------------------------------------

* finlit: Number of Big Three questions correct (0-3)
*   1. Compound interest (saving $100 at 2% for 5 years)
*   2. Inflation (1% interest vs 2% inflation)  
*   3. Risk diversification (single stock vs mutual fund)

label var finlit "Big Three financial literacy score (0-3)"

* Binary: All three correct
gen finlit_3c = (finlit == 3)
label var finlit_3c "All Big Three questions correct"

*------------------------------------------------------------------------------
* 2.5 Rescale wealth/income to $100,000 units (for readable coefficients)
*------------------------------------------------------------------------------

gen networth100k = networth / 100000
gen asset100k = asset / 100000
gen fin100k = fin / 100000
gen nfin100k = nfin / 100000  
gen income100k = income / 100000

label var networth100k "Net worth ($100k)"
label var fin100k "Financial assets ($100k)"
label var nfin100k "Non-financial assets ($100k)"
label var income100k "Income ($100k)"

********************************************************************************
* PART 3: DESCRIPTIVE STATISTICS
********************************************************************************

* Keep only first implicate for summary stats
preserve
keep if implic == 1

di _n "========================================="
di "  DESCRIPTIVE STATISTICS (Weighted)"
di "==========================================="

* Overall sample characteristics
sum age female black hispanic ed_lshs ed_hs ed_sc married kids ///
    networth100k income100k [aw=x42001]

* Financial literacy distribution
di _n "*** Financial Literacy Distribution ***"
tab finlit [aw=x42001]
tab finlit_3c [aw=x42001]

* Financial literacy by education
di _n "*** Financial Literacy by Education ***"
bysort edcl: tab finlit_3c [aw=x42001]

* Financial literacy by race
di _n "*** Financial Literacy by Race ***"
bysort racecl4: tab finlit_3c [aw=x42001]

restore

********************************************************************************
* PART 4: MAIN ANALYSIS - TABLE 3 REPLICATION
********************************************************************************

* Use first implicate only
* Note: Original paper uses scfcombo to pool across all 5 implicates
* This replication uses standard qreg for simplicity
keep if implic == 1

* Define control variables (matching Table 3)
global controls age female black hispanic raceoth ///
                ed_lshs ed_hs ed_sc ///
                married widowed ntmarried kids ///
                slfemply rtrddsbl ntworkng income100k

* Install outreg2 if needed
capture which outreg2
if _rc ssc install outreg2

*------------------------------------------------------------------------------
* PANEL A: Financial Literacy Index (continuous, 0-3)
*------------------------------------------------------------------------------

di _n "========================================="
di "  PANEL A: FINLIT INDEX (0-3)"
di "==========================================="

* Net worth
qreg networth100k finlit $controls [iw=x42001], vce(robust)
estimates store net_finlit
outreg2 using "output/tables/table3a.tex", replace ///
    ctitle("Net Worth") label bdec(3) sdec(3) ///
    keep(finlit age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

* Financial assets  
qreg fin100k finlit $controls [iw=x42001], vce(robust)
estimates store fin_finlit
outreg2 using "output/tables/table3a.tex", append ///
    ctitle("Financial Assets") label bdec(3) sdec(3) ///
    keep(finlit age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

* Non-financial assets
qreg nfin100k finlit $controls [iw=x42001], vce(robust)
estimates store nfin_finlit
outreg2 using "output/tables/table3a.tex", append ///
    ctitle("Non-Financial Assets") label bdec(3) sdec(3) ///
    keep(finlit age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

* Wealth-to-income ratio
qreg rwlth_incm finlit $controls [iw=x42001], vce(robust)
estimates store ratio_finlit
outreg2 using "output/tables/table3a.tex", append ///
    ctitle("Wealth/Income") label bdec(3) sdec(3) ///
    keep(finlit age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

*------------------------------------------------------------------------------
* PANEL B: All Big Three Correct (binary)
*------------------------------------------------------------------------------

di _n "========================================="
di "  PANEL B: ALL BIG THREE CORRECT"
di "==========================================="

* Net worth
qreg networth100k finlit_3c $controls [iw=x42001], vce(robust)
estimates store net_big3
outreg2 using "output/tables/table3b.tex", replace ///
    ctitle("Net Worth") label bdec(3) sdec(3) ///
    keep(finlit_3c age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

* Financial assets
qreg fin100k finlit_3c $controls [iw=x42001], vce(robust)
estimates store fin_big3
outreg2 using "output/tables/table3b.tex", append ///
    ctitle("Financial Assets") label bdec(3) sdec(3) ///
    keep(finlit_3c age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

* Non-financial assets
qreg nfin100k finlit_3c $controls [iw=x42001], vce(robust)
estimates store nfin_big3
outreg2 using "output/tables/table3b.tex", append ///
    ctitle("Non-Financial Assets") label bdec(3) sdec(3) ///
    keep(finlit_3c age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

* Wealth-to-income ratio
qreg rwlth_incm finlit_3c $controls [iw=x42001], vce(robust)
estimates store ratio_big3
outreg2 using "output/tables/table3b.tex", append ///
    ctitle("Wealth/Income") label bdec(3) sdec(3) ///
    keep(finlit_3c age female black hispanic ed_lshs ed_hs ed_sc) ///
    addtext(Controls, Yes, Weights, Survey) nocons

********************************************************************************
* PART 5: EXPORT SUMMARY TABLE
********************************************************************************

* Create clean comparison table
esttab net_finlit fin_finlit nfin_finlit ratio_finlit ///
    using "output/tables/table3_summary.txt", replace ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(finlit) ///
    title("Table 3 Replication: Panel A (FinLit Index)") ///
    mtitles("Net Worth" "Fin Assets" "Non-Fin Assets" "Wealth/Income") ///
    nonotes

esttab net_big3 fin_big3 nfin_big3 ratio_big3 ///
    using "output/tables/table3_summary.txt", append ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(finlit_3c) ///
    title("Table 3 Replication: Panel B (All Big Three Correct)") ///
    mtitles("Net Worth" "Fin Assets" "Non-Fin Assets" "Wealth/Income") ///
    nonotes

di _n "========================================="
di "  ANALYSIS COMPLETE"
di "==========================================="
di "Output saved to: output/tables/"
di " - table3a.tex (Panel A: FinLit Index)"
di " - table3b.tex (Panel B: Big Three Binary)"  
di " - table3_summary.txt (Combined)"

log close