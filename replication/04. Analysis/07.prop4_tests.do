/*==============================================================================
PURPOSE:  Dynamic specialization results and the two tests of the
          complementarity proposition (internal x external integration).

          (A) Event studies: effect of the PIN-induced reduction in travel
              time on transport-cost-sensitive export crops by decade
              (TWFE, 1974 base year), separately for
                (i)  the extensive margin: 1{area > 0}
                (ii) log area
          (B) Test 1 (extensive-margin complementarity): the average
              post-liberalization interaction coefficient exceeds the
              pre-liberalization one.
          (C) Test 2 (intensive-margin separability): for incumbent
              producers, the elasticity of area to actual travel-time
              changes is equal before and after liberalization.

          Periods: 1974, 1980, 1991, 2000, 2010 (PAM years); transitions
          74-80 and 80-91 are classified pre-liberalization, 91-00 and
          00-10 post. Travel times: fm1970, fm1980, fm1990, fm2000, fm2010
          matched to the nearest PAM year.

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   displayed estimates (export to tables when finalized)
==============================================================================*/

import delimited "$input\freight\product_class.csv", clear varnames(1) encoding(utf-8)
keep product category_ex5
tempfile class
save `class'

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(3) nogen
gen issoy = strpos(product, "Soja") > 0
collapse (sum) area_ha (max) issoy, by(micro year category_ex5)
keep if category_ex5 == "exp_sensitive"
tempfile expnew
save `expnew'

* Soy-only panel
use "$temp\landshare_micro.dta", clear
keep if strpos(product, "Soja") > 0
collapse (sum) area_ha, by(micro year)
gen category_ex5 = "soy_only"
append using `expnew'
drop issoy

merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf fm1970 fm1980 fm1990 fm2000 fm2010 fmpnv)
gen dltt_pin = ln(fm1970) - ln(fmpnv)

* Travel time in force at each PAM year
gen fm_t = fm1970 if year == 1974
replace fm_t = fm1980 if year == 1980
replace fm_t = fm1990 if year == 1991
replace fm_t = fm2000 if year == 2000
replace fm_t = fm2010 if year == 2010
gen lfm_t = ln(fm_t)

gen pos   = area_ha > 0
gen larea = ln(area_ha)

* Explicit PIN x year interactions with 1974 as the omitted base year
* (factor notation lets Stata drop an arbitrary collinear interaction)
foreach y in 1980 1991 2000 2010 {
    gen pinX`y' = dltt_pin * (year == `y')
}

foreach g in exp_sensitive soy_only {

    di as result "========== `g' =========="

    * ---- (A-i) Extensive-margin event study ----
    quietly areg pos i.year pinX1980 pinX1991 pinX2000 pinX2010 ///
        if category_ex5 == "`g'", absorb(micro) vce(cluster micro)
    di as result "--- extensive margin 1{area>0}: PIN x year ---"
    foreach y in 1980 1991 2000 2010 {
        local b = _b[pinX`y']
        local p = 2*ttail(e(df_r), abs(`b'/_se[pinX`y']))
        di as result "===EXT `g' `y': " %8.4f `b' " (p = " %5.3f `p' ")"
    }
    * Test 1: average post (1991,2000,2010) minus pre (1980)
    quietly lincom (pinX1991 + pinX2000 + pinX2010)/3 - pinX1980
    local p = 2*ttail(e(df_r), abs(r(estimate)/r(se)))
    di as result "===TEST1 `g' post-pre: " %8.4f r(estimate) ///
        " (p = " %5.3f `p' ")"

    * ---- (A-ii) Log-area event study (positive observations) ----
    quietly areg larea i.year pinX1980 pinX1991 pinX2000 pinX2010 ///
        if category_ex5 == "`g'" & pos, absorb(micro) vce(cluster micro)
    di as result "--- log area (positive obs): PIN x year ---"
    foreach y in 1980 1991 2000 2010 {
        local b = _b[pinX`y']
        local p = 2*ttail(e(df_r), abs(`b'/_se[pinX`y']))
        di as result "===INT `g' `y': " %8.4f `b' " (p = " %5.3f `p' ")"
    }

    * ---- (C) Test 2: incumbents' elasticity, pre vs post ----
    preserve
    quietly {
        keep if category_ex5 == "`g'"
        bysort micro: egen npos = total(pos)
        keep if npos == 5          // incumbents: positive in all five years
        xtset micro year
        sort micro year
        by micro: gen dlny  = larea - larea[_n-1]
        by micro: gen dlntt = lfm_t - lfm_t[_n-1]
        gen post = inlist(year, 2000, 2010)   // transitions 91-00, 00-10
        drop if missing(dlny)
        count if year == 1980
        local ninc = r(N)
        reg dlny c.dlntt#i.post i.year, cluster(uf)
    }
    local bpre  = _b[0.post#c.dlntt]
    local bpost = _b[1.post#c.dlntt]
    local ppre  = 2*ttail(e(df_r), abs(`bpre'/_se[0.post#c.dlntt]))
    local ppost = 2*ttail(e(df_r), abs(`bpost'/_se[1.post#c.dlntt]))
    di as result "===TEST2 `g' incumbents: " `ninc'
    di as result "===TEST2 `g' elasticity pre:  " %8.3f `bpre' ///
        " (p = " %5.3f `ppre' ")"
    di as result "===TEST2 `g' elasticity post: " %8.3f `bpost' ///
        " (p = " %5.3f `ppost' ")"
    quietly test 0.post#c.dlntt = 1.post#c.dlntt
    di as result "===TEST2 `g' equality p = " %5.3f r(p)
    restore
}
