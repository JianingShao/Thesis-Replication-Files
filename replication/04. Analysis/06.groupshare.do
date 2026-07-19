/*==============================================================================
PURPOSE:  Estimate travel-time gradients of agricultural land shares for six
          broad product categories, following the design of Fajgelbaum and
          Redding (2022), Table 5: one PPML regression per category, allowing
          zero land shares, with travel time instrumented by the travel time
          on a historical/planned network.

          Categories (see $input\freight\product_class.csv, column category6):
            grains_oilseeds  bulk export crops (soy, corn, rice, wheat, ...)
            industrial       high value per ton or processed at origin
                             (coffee, cotton, cocoa, tobacco, sugarcane, ...)
            staples          domestic food staples (beans, cassava, potatoes)
            fruits_veg       perishable fruits and vegetables
            pasture          cattle pasture equivalent

          Specifications per category:
            (1) PPML: share_2010 on log travel time 2010, lat, lon, log area
            (2) PPML with control function: log travel time 2010 instrumented
                by log travel time on the PIN (planned) network
            (3) Long difference: D.share on actual reduction in log travel
                time, instrumented by the PIN-induced reduction, with initial
                share, lat, lon, log area, and state fixed effects
            (4) PPML: share_1974 on log travel time 1970 (initial sorting)

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   $tables\landshare\groupshare_results.csv
==============================================================================*/

global tables "$root\05. Tables and Figures"
capture mkdir "$tables\landshare"

*----------------- 1. Group land shares --------------------------------------*

* Grouping column from product_class.csv; default is the export-based
* classification (category_final); set $groupvar to category6 for the
* broad-category variant
if "$groupvar" == "" global groupvar "category_final"

import delimited "$input\freight\product_class.csv", ///
    clear varnames(1) encoding(utf-8)
keep product $groupvar
rename $groupvar catg
tempfile class
save `class'

use "$temp\landshare_micro.dta", clear
keep if inlist(year, 1974, 2010)
merge m:1 product using `class', keep(3) nogen
collapse (sum) area_ha (first) total_agland, by(micro year catg)
gen share = area_ha / total_agland
keep micro year catg share
reshape wide share, i(micro catg) j(year)
foreach v of varlist share1974 share2010 {
    replace `v' = 0 if missing(`v')
}

* Treatment and controls
merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf fm1970 fm2010 fmpnv lat lon area)
gen lfm2010     = ln(fm2010)
gen lfm1970     = ln(fm1970)
gen lfmpnv      = ln(fmpnv)
gen dltt_actual = lfm1970 - lfm2010
gen dltt_pin    = lfm1970 - lfmpnv
gen larea       = ln(area)
gen dshare      = share2010 - share1974

*----------------- 2. Per-category regressions -------------------------------*

tempname res
postfile `res' str20 category ///
    b_ppml se_ppml b_ppml_iv se_ppml_iv fs_F b_ld_iv se_ld_iv ///
    b_ppml74 se_ppml74 ///
    using "$temp\groupshare_results.dta", replace

levelsof catg, local(cats)
foreach c of local cats {
    quietly {
        preserve
        keep if catg == "`c'"

        * (1) PPML level 2010 (FR 2022, Table 5, col 1)
        poisson share2010 lfm2010 lat lon larea, vce(robust) iterate(50)
        local b1  = _b[lfm2010]
        local s1  = _se[lfm2010]

        * (2) PPML with control function: instrument = PIN-network time
        reg lfm2010 lfmpnv lat lon larea, vce(robust)
        test lfmpnv
        local fsF = r(F)
        predict cf_resid, residuals
        poisson share2010 lfm2010 cf_resid lat lon larea, ///
            vce(robust) iterate(50)
        local b2  = _b[lfm2010]
        local s2  = _se[lfm2010]

        * (3) Long difference with IV (paper's baseline design)
        ivregress 2sls dshare (dltt_actual = dltt_pin) ///
            share1974 lat lon larea i.uf, cluster(uf)
        local b3  = _b[dltt_actual]
        local s3  = _se[dltt_actual]

        * (4) PPML level 1974 on the 1970 network (initial sorting)
        poisson share1974 lfm1970 lat lon larea, vce(robust) iterate(50)
        local b4  = _b[lfm1970]
        local s4  = _se[lfm1970]

        post `res' ("`c'") (`b1') (`s1') (`b2') (`s2') (`fsF') ///
            (`b3') (`s3') (`b4') (`s4')
        restore
    }
}
postclose `res'

*----------------- 3. Report --------------------------------------------------*

use "$temp\groupshare_results.dta", clear
gen t_ppml_iv = b_ppml_iv / se_ppml_iv
gen t_ld_iv   = b_ld_iv / se_ld_iv
format b_* se_* t_* %9.3f
format fs_F %9.1f
list category b_ppml_iv se_ppml_iv t_ppml_iv b_ld_iv se_ld_iv t_ld_iv ///
    fs_F, noobs abbreviate(12)
list category b_ppml se_ppml b_ppml74 se_ppml74, noobs abbreviate(12)

export delimited using ///
    "$tables\landshare\groupshare_results_${groupvar}.csv", replace

* Note: control-function standard errors in (2) do not account for the
* first-stage estimation step; bootstrap for publication-grade inference.
