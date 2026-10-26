/*==============================================================================
PURPOSE:  Estimate travel-time gradients of agricultural land shares for
          product categories, following Fajgelbaum and Redding (2022). Long-
          difference IV of the change in a category's land share on the actual
          reduction in log travel time, instrumented by the PIN-induced
          reduction, across three control sets, plus the 1974 PPML level.

          Specifications per category:
            (1) LD-IV: D.share on travel-time reduction, initial share only
            (2) LD-IV: (1) + state fixed effects
            (3) LD-IV: (2) + lat, lon, log area (paper's baseline design)
            (4) PPML: share_1974 on log travel time 1970 (initial sorting)

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   $temp\groupshare_results.dta
==============================================================================*/

global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input "$root\01. Raw Data"
global tables "$root\05. Tables and Figures"
global temp "$root\02. Cleaning\temp"
global output "$root\03. Final Datasets"
capture mkdir "$tables\landshare"

*----------------- 1. Group land shares --------------------------------------*

import delimited "$input\freight\product_class.csv", ///
    clear varnames(1) encoding(utf-8)
keep product category_ex5
rename category_ex5 catg
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
    b_ppml se_ppml b_ppml_iv se_ppml_iv b_ld_iv se_ld_iv ///
    b_ppml74 se_ppml74 ///
    using "$temp\groupshare_results.dta", replace

levelsof catg, local(cats)
foreach c of local cats {

        preserve
        keep if catg == "`c'"

        * (1) Long difference with IV
        ivregress 2sls dshare (dltt_actual = dltt_pin) ///
            share1974, cluster(uf)
        local b1  = _b[dltt_actual]
        local s1  = _se[dltt_actual]

        * (2) Long difference with IV
        ivregress 2sls dshare (dltt_actual = dltt_pin) ///
            share1974 i.uf, cluster(uf)
        local b2  = _b[dltt_actual]
        local s2  = _se[dltt_actual]

        * (3) Long difference with IV (paper's baseline design)
        ivregress 2sls dshare (dltt_actual = dltt_pin) ///
            share1974 lat lon larea i.uf, cluster(uf)
        local b3  = _b[dltt_actual]
        local s3  = _se[dltt_actual]

        * (4) PPML level 1974 on the 1970 network (initial sorting)
        poisson share1974 lfm1970 lat lon larea, vce(robust) iterate(50)
        local b4  = _b[lfm1970]
        local s4  = _se[lfm1970]

        post `res' ("`c'") (`b1') (`s1') (`b2') (`s2') ///
            (`b3') (`s3') (`b4') (`s4')
        restore

}
postclose `res'
