/*==============================================================================
PURPOSE:  Pooled transport-sensitivity interaction (the Cosar-Fajgelbaum /
          theta design), the powered test of the specialization proposition.

          Stack all traded crops g x micro-regions l in a long difference,
          1974-2010:
            Y_gl = a_g + a_l + b (tau_g x DTT_l) + e_gl
          Product FE a_g absorb the good-specific price and the tau_g main
          effect; micro-region FE a_l absorb the CES denominator and the DTT_l
          main effect; only the interaction is identified. DTT_l (actual log
          travel-time reduction) is instrumented by the PIN-induced reduction,
          so the endogenous interaction tau_g x DTT_l is instrumented by
          tau_g x PIN_l. Fixed location-good comparative advantage T_gl is
          differenced out. Clustering is at the micro-region (531 clusters),
          which resolves the few-cluster problem of the two-group design.

          tau_g proxies:
            (a) binary: 1 for transport-sensitive export crops, 0 for
                insensitive (the differential response; b > 0 predicted)
            (b) continuous: log value per ton (inverse of tau; b < 0 predicted)
          Outcomes: D log(area+1) and D land share.

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   displayed estimates
==============================================================================*/

global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input = "$root\01. Raw Data"
global temp = "$root\02. Cleaning\temp"
global output = "$root\03. Final Datasets"

capture which ivreghdfe
if _rc ssc install ivreghdfe, replace
capture which reghdfe
if _rc ssc install reghdfe, replace
capture which ftools
if _rc ssc install ftools, replace

import delimited "$input\freight\product_class.csv", clear varnames(1) encoding(utf-8)
keep product category_ex5
tempfile class
save `class'

* National value per ton (2010), tau proxy
use "$temp\landshare_micro.dta", clear
keep if year == 2010
collapse (sum) value_prod quantity, by(product)
gen lnvpt = ln(1000 * value_prod / quantity)
keep product lnvpt
tempfile vpt
save `vpt'

* Traded-crop x micro panel, long difference
use "$temp\landshare_micro.dta", clear
keep if inlist(year, 1974, 2010)
merge m:1 product using `class', keep(3) nogen
keep if inlist(category_ex5, "exp_sensitive", "exp_insensitive")
keep micro product category_ex5 year area_ha total_agland
gen share = area_ha / total_agland
reshape wide area_ha share total_agland, i(micro product) j(year)
foreach v of varlist area_ha1974 area_ha2010 share1974 share2010 {
    replace `v' = 0 if missing(`v')
}
gen dlnarea = ln(area_ha2010 + 1) - ln(area_ha1974 + 1)
gen dshare  = share2010 - share1974

merge m:1 product using `vpt', keep(3) nogen
merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(fm1970 fm2010 fmpnv)
gen dtt_actual = ln(fm1970) - ln(fm2010)
gen dtt_pin    = ln(fm1970) - ln(fmpnv)

egen prodid = group(product)
gen sens = category_ex5 == "exp_sensitive"

* Interactions and their instruments
gen sens_dtt  = sens * dtt_actual
gen sens_pin  = sens * dtt_pin
gen vpt_dtt   = lnvpt * dtt_actual
gen vpt_pin   = lnvpt * dtt_pin

di as result _n "===== (a) BINARY tau contrast: sensitive x DTT ====="
di as txt "--- outcome: D log(area+1) ---"
ivreghdfe dlnarea (sens_dtt = sens_pin), absorb(prodid micro) cluster(micro) first
di as txt "--- outcome: D share ---"
ivreghdfe dshare  (sens_dtt = sens_pin), absorb(prodid micro) cluster(micro)

di as result _n "===== (b) CONTINUOUS tau proxy: log value/ton x DTT ====="
di as txt "--- outcome: D log(area+1) ---"
ivreghdfe dlnarea (vpt_dtt = vpt_pin), absorb(prodid micro) cluster(micro)
di as txt "--- outcome: D share ---"
ivreghdfe dshare  (vpt_dtt = vpt_pin), absorb(prodid micro) cluster(micro)
