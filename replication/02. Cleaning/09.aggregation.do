/*==============================================================================
PURPOSE:  Assemble the final analysis datasets. This is the ONLY script that
          writes to 03. Final Datasets; every other cleaning script writes to
          $temp and this one merges.

          Three outputs, one per unit of analysis:
            micro.dta        531 consistent micro-regions, wide by year
            meso.dta         132 meso-regions, wide by year
            croppanel.dta    traded crop x micro-region, the pooled-tau panel

INPUT:    $temp\traveltime_{micro,meso}.dta and the per-series files listed in
          $data_micro / $data_meso below, plus $temp\croppanel_micro.dta
OUTPUT:   $output\micro.dta, $output\meso.dta, $output\croppanel.dta

NOTES:  1. YEAR LABELS. Series arrive on their own survey years and are
           relabelled to a common decadal grid: 1973 and 1974 -> 1970,
           1991 -> 1990. So soy1970 and sens1970 are the 1974 surveys, and
           gdp1970 is the 1970 census.
        2. The soy/cotton/cattle spreadsheet series were dropped in 2026-08.
           They came from soy.xls, cotton.xls and cattle.xls -- a separate
           source from the PAM/PPM pulls -- and measured production where the
           category columns measure harvested area, which is what made the two
           disagree. Everything crop-related now comes from PAM/PPM through
           06.landshare.do. The producing script is in 02. Cleaning/archive/.
           Validation: pasture (PPM head count via landshare) reproduces the
           old cattle series exactly in the long difference, 0.465 / -0.185 /
           0.506 across the three T9 panels.
==============================================================================*/

*--------- helper: relabel a year suffix, skipping if nothing matches --------*
* The old code called `ds *73' unguarded, which errors out when no variable
* carries that suffix. Since the soy/cotton spreadsheet series were dropped,
* nothing ends in 73 or 74 any more, so the calls must tolerate no match.
capture program drop yrsub
program define yrsub
    args from to
    capture ds *`from'
    if _rc != 0 exit
    local vl `r(varlist)'
    foreach var of local vl {
        local newname = subinstr("`var'", "`from'", "`to'", .)
        capture rename `var' `newname'
    }
end

*=============================== MICRO ======================================*

use "$temp\traveltime_micro", clear
global data_micro "gdp pop urbpop eap_urban eap_rural agroemp geo waterway dis_capital category namedcrop"
foreach d in $data_micro {
    merge 1:1 micro using "$temp/`d'_micro.dta"
    drop _merge
}
* drop oversea island
drop if micro==26019
* suitability
drop if arrival_time_1970_amc_micro==.

*clean
ds *_micro
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "_micro", "", .)
    rename `var' `newname'
}
yrsub 73 70
yrsub 74 70
yrsub 91 90
ds arrival_time_*_amc
foreach var in `r(varlist)' {
    local tempname = subinstr("`var'", "arrival_time_", "", .)
    local year = subinstr("`tempname'", "_amc", "", .)
    local newname = "fm" + "`year'"
    rename `var' `newname'
}
rename emp2006 emp2010
rename gdp1996 gdp1995
foreach year in 1950 1960 1970 1980 1990 2000 2010{
    gen urbshare`year' = urbpop`year'/pop`year'
}
foreach year in 1970 1980 1990 2000 2010{
    gen eapurbshare`year' = eap_urban`year'/(eap_urban`year'+eap_rural`year')
}

note: category columns for 1970 and 1990 are the PAM 1974 and 1991 surveys
save "$output\micro.dta", replace

*=============================== MESO =======================================*

use "$temp\traveltime_meso", clear
global data_meso "gdp pop urbpop eap_urban eap_rural agroemp geo category"
foreach d in $data_meso {
    merge 1:1 meso using "$temp/`d'_meso.dta"
    drop _merge
}

*clean
ds *_meso
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "_meso", "", .)
    rename `var' `newname'
}
yrsub 73 70
yrsub 74 70
yrsub 91 90
ds arrival_time_*_amc
foreach var in `r(varlist)' {
    local tempname = subinstr("`var'", "arrival_time_", "", .)
    local year = subinstr("`tempname'", "_amc", "", .)
    local newname = "fm" + "`year'"
    rename `var' `newname'
}
rename emp2006 emp2010
rename gdp1996 gdp1995
foreach year in 1950 1960 1970 1980 1990 2000 2010{
    gen urbshare`year' = urbpop`year'/pop`year'
}
foreach year in 1970 1980 1990 2000 2010{
    gen eapurbshare`year' = eap_urban`year'/(eap_urban`year'+eap_rural`year')
}

note: category columns for 1970 and 1990 are the PAM 1974 and 1991 surveys
save "$output\meso.dta", replace

*=========================== CROP x MICRO PANEL =============================*
* Carries the micro-region treatment, instrument and controls alongside the
* crop-level outcomes, so the pooled-tau table needs this file alone.
*
* Year suffixes here stay on the true PAM survey years (area_ha1974, not
* area_ha1970) and yrsub is deliberately not applied. The decadal relabel above
* exists so that series with different survey years line up in one long
* difference; this file has exactly two periods with the differences already
* computed, so there is nothing to line up and the honest year is clearer.

use "$temp\croppanel_micro.dta", clear
merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf sigla region lat lon area fm1970 fm2010 fmpnv dist_cap)

gen double dtt_actual = ln(fm1970) - ln(fm2010)
gen double dtt_pin    = ln(fm1970) - ln(fmpnv)
label var dtt_actual "D log travel time to port, 1970-2010"
label var dtt_pin    "PIN-induced reduction in log travel time (instrument)"

* The interaction and its instrument, for both tau proxies
gen double sens_dtt = sens  * dtt_actual
gen double sens_pin = sens  * dtt_pin
gen double vpt_dtt  = lnvpt * dtt_actual
gen double vpt_pin  = lnvpt * dtt_pin
label var sens_dtt "binary tau x D log travel time"
label var sens_pin "binary tau x PIN  (instrument)"
label var vpt_dtt  "ln value/ton x D log travel time"
label var vpt_pin  "ln value/ton x PIN  (instrument)"

sort micro prodid
save "$output\croppanel.dta", replace

*=========================== PRODUCT LOOKUP =================================*
* Product-level attributes: category, export ratio, value per tonne, base-year
* prevalence. A fourth unit of observation, so it gets its own file rather than
* being folded into a location-level dataset.

use "$temp\products.dta", clear
label var category_ex5 "Settled product category"
label var ex_g         "FAOSTAT export ratio, mean over available years"
label var vpt          "National value per tonne, 2010 R$"
label var lnvpt        "ln value per tonne"
sort product
save "$output\products.dta", replace

*=============================== REPORT =====================================*

di as result ""
di as result "=== final datasets ==="
foreach f in micro meso croppanel {
    quietly use "$output/`f'.dta", clear
    di as result "    " %-12s "`f'.dta" %6.0f _N " rows, " %4.0f c(k) " variables"
}

use "$output\micro.dta", clear
di as result ""
di as result "  micro.dta category columns, means 1974 -> 2010:"
foreach v in agland cropland sens ins past dom proc {
    quietly sum `v'1970
    local m = r(mean)
    quietly sum `v'2010
    di as result "    " %-10s "`v'" %14.0f `m' " -> " %14.0f r(mean)
}
foreach v in sens ins {
    quietly count if `v'1970 == 0
    di as result "    micro-regions with zero `v' in 1974: " %4.0f r(N)
}
