/*==============================================================================
PURPOSE:  Test of trade frontier (Proposition 1) via the nonlinear extensive-
          margin response to travel-time reductions. The model predicts a
          hump-shaped response in initial remoteness: locations already open
          respond intensively, frontier-adjacent locations enter, deep interior
          stays closed. Uses 1991 endline (when frontier was still interior) and
          flexible quadratic interaction to trace the shape.

          Tests:
          (A) Nonlinearity in initial remoteness (1974-1991 entry): the PIN-
              induced travel-time reduction's effect on entry into sensitive-
              export production should be hump-shaped, peaking at the frontier.
              Outcome: entry into sensitive-export production, 1974-1991.
          (B) Goods-range margin: remote micro-regions produce narrower export-
              product range; range widens as travel time falls.
              Outcome: count of distinct traded-category products with positive area.

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   displayed estimates, $temp\frontier_hump_*,
          $tables\frontier_hump.png

RESULT (run 2026-07-28): hump NOT found. beta3 > 0 (convex), so g(t) has a
          minimum, not a peak, and over the support the entry response declines
          monotonically in remoteness. Chief reason: the binary entry outcome is
          near-degenerate -- 84.8% of micro-regions already grew a sensitive
          crop in 1974, and only 10 of 531 switch 0->1 by 1991 (70 switch 1->0),
          so "entry" is really measuring exit. See the diagnostic block below.
==============================================================================*/

global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input "$root\01. Raw Data"
global tables "$root\05. Tables and Figures"
global temp "$root\02. Cleaning\temp"
global output "$root\03. Final Datasets"

*----------------- Setup: load classification and prepare data ----------------*

import delimited "$input\freight\product_class.csv", clear varnames(1) encoding(utf-8)
keep product category_ex5
tempfile class
save `class'

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(3) nogen
gen traded = inlist(category_ex5, "exp_sensitive", "exp_insensitive")
gen possens = area_ha > 0 & !missing(area_ha) & category_ex5 == "exp_sensitive"
gen nsens   = possens
gen postrad = area_ha > 0 & !missing(area_ha) & traded
collapse (max) possens (sum) nsens (sum) nprod = postrad, by(micro year)
keep if inlist(year, 1974, 1991, 2010)
reshape wide possens nsens nprod, i(micro) j(year)

merge 1:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf fm1970 fm1990 fm2010 fmpnv lat lon area)
gen dltt_actual_91  = ln(fm1970) - ln(fm1990)
gen dltt_pin_91     = ln(fm1970) - ln(fmpnv)
gen lfm1970         = ln(fm1970)
gen lfm1990         = ln(fm1990)
gen larea           = ln(area)
gen lfm1970_sq      = lfm1970^2

*----------------- (0) Diagnostics: is the entry outcome usable? --------------*

gen entry_91  = possens1991 - possens1974
gen dnsens_91 = nsens1991 - nsens1974

di as result "===0 Support of the remoteness variable and outcome variation:"
sum fm1970 lfm1970 dltt_pin_91
di as result "  lfm1970 percentiles (the range over which g(t) is identified):"
_pctile lfm1970, p(5 25 50 75 95)
di as result "    p5 = " %5.2f r(r1) "  p25 = " %5.2f r(r2) "  p50 = " %5.2f r(r3) ///
    "  p75 = " %5.2f r(r4) "  p95 = " %5.2f r(r5)
di as result "  Binary sensitive-presence indicator by year:"
tab possens1974
tab possens1991
di as result "  entry_91 (-1 = exit, +1 = entry): the identifying variation"
tab entry_91
di as result "  Count of sensitive crops present (a non-degenerate alternative):"
tab nsens1974
sum dnsens_91

*----------------- (A) Nonlinearity in initial remoteness: 1974-1991 entry -----*

* Flexible quadratic design: marginal effect of PIN-induced TT reduction
* is g(t) = β₁ + β₂·t + β₃·t², testing β₃ < 0 (inverted-U).
* Use Δt^PIN (reduced form) as regressor to avoid instrumenting interactions.

reg entry_91 c.dltt_pin_91##(c.lfm1970 c.lfm1970_sq) ///
    possens1974 lat lon larea i.uf, cluster(uf)

local b1 = _b[c.dltt_pin_91]
local b2 = _b[c.dltt_pin_91#c.lfm1970]
local b3 = _b[c.dltt_pin_91#c.lfm1970_sq]

di as result "===A Nonlinearity test (1974-1991 entry):"
di as result "  β₁ (Δt^PIN):        " %8.4f `b1'
di as result "  β₂ (Δt^PIN × t):    " %8.4f `b2'
di as result "  β₃ (Δt^PIN × t²):   " %8.4f `b3'
di as result "  Frontier t* = -β₂/(2β₃) = " %8.4f -`b2'/(2*`b3')
di as result "  Joint F (Δt^PIN terms): "
test c.dltt_pin_91 c.dltt_pin_91#c.lfm1970 c.dltt_pin_91#c.lfm1970_sq

* Save for later plotting
estimates save "$temp\frontier_hump_entry_91", replace

* The sign of b3 alone is not the test: evaluate g(t) over the actual support.
* b3 > 0 means g is convex (minimum at t*), b3 < 0 means the predicted hump.
di as result ""
di as result "===A g(t) = dE[entry]/d(dlt^PIN) evaluated over the support:"
di as result "     t   TT(h)      g(t)      se       p           95% CI"
tempname gt
matrix `gt' = J(9, 4, .)
local i = 1
forvalues tx = 30(5)70 {
    local t = `tx'/10
    quietly lincom dltt_pin_91 + `t'*c.dltt_pin_91#c.lfm1970 ///
        + (`t'*`t')*c.dltt_pin_91#c.lfm1970_sq
    di as result "  " %5.2f `t' " " %6.0f exp(`t') "  " %8.4f r(estimate) ///
        "  " %7.4f r(se) "  " %5.3f r(p) ///
        "  [" %7.4f r(lb) ", " %7.4f r(ub) "]"
    matrix `gt'[`i', 1] = `t'
    matrix `gt'[`i', 2] = r(estimate)
    matrix `gt'[`i', 3] = r(lb)
    matrix `gt'[`i', 4] = r(ub)
    local ++i
}

* Nonparametric counterpart: no functional form imposed on the shape.
di as result ""
di as result "===A' Nonparametric shape (PIN reduction x quintile of t_1970):"
xtile q5 = lfm1970, nq(5)
quietly reg entry_91 i.q5 c.dltt_pin_91#i.q5 possens1974 lat lon larea i.uf, ///
    cluster(uf)
forvalues k = 1/5 {
    quietly sum fm1970 if q5 == `k', meanonly
    local mt = r(mean)
    local b  = _b[`k'.q5#c.dltt_pin_91]
    local se = _se[`k'.q5#c.dltt_pin_91]
    local p  = 2*ttail(e(df_r), abs(`b'/`se'))
    di as result "  Q`k' (mean TT " %6.1f `mt' "h): " %8.4f `b' ///
        " (se " %6.4f `se' ", p " %5.3f `p' ")"
}
di as result "  Equality of the five quintile slopes:"
test 1.q5#c.dltt_pin_91 = 2.q5#c.dltt_pin_91 = 3.q5#c.dltt_pin_91 = ///
     4.q5#c.dltt_pin_91 = 5.q5#c.dltt_pin_91

* Same design on the non-degenerate count outcome.
di as result ""
di as result "===A'' Same design, outcome = change in NUMBER of sensitive crops:"
reg dnsens_91 c.dltt_pin_91##(c.lfm1970 c.lfm1970_sq) ///
    nsens1974 lat lon larea i.uf, cluster(uf)
di as result "  b3 (Dt^PIN x t^2) = " %8.4f _b[c.dltt_pin_91#c.lfm1970_sq] ///
    "  (hump requires b3 < 0)"
test c.dltt_pin_91 c.dltt_pin_91#c.lfm1970 c.dltt_pin_91#c.lfm1970_sq

*----------------- (A''') Plot g(t) with CI band over the support --------------*

preserve
    quietly svmat double `gt', names(g)
    label var g1 "log travel time to port, 1970"
    twoway ///
        (rarea g3 g4 g1, color(gs12) lwidth(none)) ///
        (line  g2 g1, lcolor(navy) lwidth(medthick)) ///
        , yline(0, lcolor(gs8) lpattern(dash)) ///
          xline(4.212 5.113, lcolor(cranberry) lpattern(shortdash)) ///
          xtitle("Initial log travel time to port, t{subscript:1970}") ///
          ytitle("Marginal effect g(t) of PIN travel-time reduction" ///
                 "on entry into sensitive-export production") ///
          legend(order(2 "g(t)" 1 "95% CI") ring(0) pos(2) cols(1) region(lstyle(none))) ///
          note("Dashed red lines mark the interquartile range of t{subscript:1970}." ///
               "Model predicts a peak at the frontier; the estimate is convex instead.") ///
          graphregion(color(white)) plotregion(color(white))
    graph export "$tables\frontier_hump.png", replace width(2000)
restore

*----------------- (B) Goods-range margin: PPML with FE ----------------------*

* Levels: range of traded goods vs. initial remoteness (1970 baseline)
* Using ppmlhdfe to properly absorb state FE
di as result ""
di as result "===B Goods-range levels:"

quietly ppmlhdfe nprod1974 lfm1970 lat lon larea, absorb(uf) vce(cluster uf)
local p = 2*normal(-abs(_b[lfm1970]/_se[lfm1970]))
di as result "  1974 (PPML-HDFE on t₁₉₇₀): " %8.4f _b[lfm1970] " (p = " %5.3f `p' ")"

quietly ppmlhdfe nprod1991 lfm1970 lat lon larea, absorb(uf) vce(cluster uf)
local p = 2*normal(-abs(_b[lfm1970]/_se[lfm1970]))
di as result "  1991 (PPML-HDFE on t₁₉₇₀): " %8.4f _b[lfm1970] " (p = " %5.3f `p' ")"

* Changes in range: Δnprod vs. PIN-induced TT reduction
gen dnprod_91 = nprod1991 - nprod1974

di as result ""
di as result "===B Goods-range change (1974-1991):"

quietly reg dnprod_91 dltt_pin_91 nprod1974 lat lon larea i.uf, cluster(uf)
local p = 2*ttail(e(df_r), abs(_b[dltt_pin_91]/_se[dltt_pin_91]))
di as result "  RF (Δt^PIN): " %8.4f _b[dltt_pin_91] " (p = " %5.3f `p' ")"

* ivregress with cluster() leaves e(df_r) missing, so use the normal reference
quietly ivregress 2sls dnprod_91 (dltt_actual_91 = dltt_pin_91) ///
    nprod1974 lat lon larea i.uf, cluster(uf)
local p = 2*normal(-abs(_b[dltt_actual_91]/_se[dltt_actual_91]))
di as result "  IV (Δt actual): " %8.4f _b[dltt_actual_91] " (p = " %5.3f `p' ")"

* Range change by initial-remoteness tercile (frontier ordering)
xtile terc = lfm1970, nq(3)
di as result "  By frontier position (initial TT tercile):"
reg dnprod_91 i.terc c.dltt_pin_91#i.terc nprod1974 lat lon larea i.uf, cluster(uf)
foreach k in 1 2 3 {
    local b = _b[`k'.terc#c.dltt_pin_91]
    local p = 2*ttail(e(df_r), abs(`b'/_se[`k'.terc#c.dltt_pin_91]))
    di as result "    Tercile `k': " %8.4f `b' " (p = " %5.3f `p' ")"
}
