/*  TA2: cardinal tau from farmgate prices, on the SETTLED 8-crop classification.
    Model: ln P_gl = ln P_g* - tau_g * t_l, so the sensitive-vs-insensitive
    difference in the travel-time gradient estimates -(tau_s - tau_i).        */
global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input  "$root\01. Raw Data"
global temp   "$root\02. Cleaning\temp"
global output "$root\03. Final Datasets"

use "$temp\landshare_micro.dta", clear
keep if inlist(year, 1974, 1991, 2010)
merge m:1 product using "$output\products.dta", keep(3) nogen ///
    keepusing(category_ex5)
keep if inlist(category_ex5, "exp_sensitive", "exp_insensitive")

* implied unit value = farmgate price
keep if quantity > 0 & value_prod > 0 & !missing(quantity, value_prod)
gen double luv  = ln(1000 * value_prod / quantity)
gen byte   sens = category_ex5 == "exp_sensitive"
egen prod_id = group(product)

merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf lat lon fm1970 fm1990 fm2010)
gen double fmy = fm1970 if year == 1974
replace    fmy = fm1990 if year == 1991
replace    fmy = fm2010 if year == 2010
gen double tt  = fmy/100
gen double lfm = ln(fmy)

di as result "=== coverage ==="
foreach y in 1974 1991 2010 {
    quietly count if year == `y'
    local n = r(N)
    quietly count if year == `y' & sens
    di as result "    `y': " %5.0f `n' " crop-region prices, of which sensitive " %4.0f r(N)
}

di as result ""
di as result "=== (A) levels: travel time per 100 hours ==="
di as result "    year   insens slope    sens differential     p        N"
foreach y in 1974 1991 2010 {
    quietly reg luv c.tt##c.sens lat lon i.prod_id i.uf if year == `y', cluster(micro)
    local b0 = _b[tt]
    local bd = _b[c.tt#c.sens]
    local sd = _se[c.tt#c.sens]
    di as result "    `y'   " %9.4f `b0' "       " %9.4f `bd' " (" %6.4f `sd' ") " ///
        %5.3f (2*ttail(e(df_r), abs(`bd'/`sd'))) "  " %5.0f e(N)
}

di as result ""
di as result "=== log travel time (constant elasticity) ==="
foreach y in 1974 1991 2010 {
    quietly reg luv c.lfm##c.sens lat lon i.prod_id i.uf if year == `y', cluster(micro)
    local bd = _b[c.lfm#c.sens]
    local sd = _se[c.lfm#c.sens]
    di as result "    `y': " %9.4f `bd' " (" %6.4f `sd' ")  p " ///
        %5.3f (2*ttail(e(df_r), abs(`bd'/`sd'))) "   N " %5.0f e(N)
}
