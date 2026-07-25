/*==============================================================================
PURPOSE:  Direct tests of the trade-frontier proposition.

          (A) Nonlinearity in initial remoteness: the extensive-margin
              response to PIN-induced travel-time reductions should be
              hump-shaped in the initial (1970) travel-time level: locations
              already open respond on the intensive margin only, locations
              near the frontier cross it, the deep interior stays closed.
              Outcome: entry into sensitive-export production, 1974-2010.
          (B) Goods-range margin (Remark on partial autarky): export margins
              close good by good with remoteness, so remote micro-regions
              produce a narrower range of traded goods, and the range widens
              where travel time falls.
              Outcome: number of distinct export-category products with
              positive area.

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   displayed estimates
==============================================================================*/

import delimited "$input\freight\product_class.csv", clear varnames(1) encoding(utf-8)
keep product category_ex5
tempfile class
save `class'

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(3) nogen
gen traded = inlist(category_ex5, "exp_sensitive", "exp_insensitive")
gen possens = area_ha > 0 & category_ex5 == "exp_sensitive"
gen postrad = area_ha > 0 & traded
collapse (max) possens (sum) nprod = postrad, by(micro year)
keep if inlist(year, 1974, 2010)
reshape wide possens nprod, i(micro) j(year)

merge 1:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf fm1970 fm2010 fmpnv lat lon area)
gen dltt_actual = ln(fm1970) - ln(fm2010)
gen dltt_pin    = ln(fm1970) - ln(fmpnv)
gen lfm1970     = ln(fm1970)
gen lfm2010     = ln(fm2010)
gen larea       = ln(area)

*----------------- (A) Nonlinearity in initial remoteness --------------------*

xtile terc = lfm1970, nq(3)
gen entry = possens2010 - possens1974

reg entry i.terc c.dltt_pin#i.terc lat lon larea i.uf, cluster(uf)
foreach k in 1 2 3 {
    local b = _b[`k'.terc#c.dltt_pin]
    local p = 2*ttail(e(df_r), abs(`b'/_se[`k'.terc#c.dltt_pin]))
    di as result "===A entry, initial-TT tercile `k': " %8.4f `b' ///
        " (p = " %5.3f `p' ")"
}
quietly lincom 2.terc#c.dltt_pin - 1.terc#c.dltt_pin
local p = 2*ttail(e(df_r), abs(r(estimate)/r(se)))
di as result "===A T2-T1: " %8.4f r(estimate) " (p = " %5.3f `p' ")"
quietly lincom 2.terc#c.dltt_pin - 3.terc#c.dltt_pin
local p = 2*ttail(e(df_r), abs(r(estimate)/r(se)))
di as result "===A T2-T3: " %8.4f r(estimate) " (p = " %5.3f `p' ")"

*----------------- (B) Goods-range margin -------------------------------------*

* Levels: range of traded goods narrows with remoteness
quietly poisson nprod1974 lfm1970 lat lon larea, vce(robust)
local p = 2*normal(-abs(_b[lfm1970]/_se[lfm1970]))
di as result "===B levels 1974 (PPML): " %8.4f _b[lfm1970] " (p = " %5.3f `p' ")"
quietly poisson nprod2010 lfm2010 lat lon larea, vce(robust)
local p = 2*normal(-abs(_b[lfm2010]/_se[lfm2010]))
di as result "===B levels 2010 (PPML): " %8.4f _b[lfm2010] " (p = " %5.3f `p' ")"

* Changes: range widens where travel time fell (baseline LD-IV design)
gen dnprod = nprod2010 - nprod1974
quietly reg dnprod dltt_pin nprod1974 lat lon larea i.uf, cluster(uf)
local p = 2*ttail(e(df_r), abs(_b[dltt_pin]/_se[dltt_pin]))
di as result "===B RF change: " %8.4f _b[dltt_pin] " (p = " %5.3f `p' ")"
quietly ivregress 2sls dnprod (dltt_actual = dltt_pin) ///
    nprod1974 lat lon larea i.uf, cluster(uf)
local p = 2*ttail(e(df_r), abs(_b[dltt_actual]/_se[dltt_actual]))
di as result "===B IV change: " %8.4f _b[dltt_actual] " (p = " %5.3f `p' ")"

* Range change by initial-remoteness tercile (frontier ordering)
reg dnprod i.terc c.dltt_pin#i.terc nprod1974 lat lon larea i.uf, cluster(uf)
foreach k in 1 2 3 {
    local b = _b[`k'.terc#c.dltt_pin]
    local p = 2*ttail(e(df_r), abs(`b'/_se[`k'.terc#c.dltt_pin]))
    di as result "===B range, initial-TT tercile `k': " %8.4f `b' ///
        " (p = " %5.3f `p' ")"
}
