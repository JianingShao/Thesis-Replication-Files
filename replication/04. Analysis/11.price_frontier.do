/*==============================================================================
PURPOSE:  Trade-frontier and cardinal-tau tests from FARMGATE PRICES.

          Motivation: land area and crop counts measure PRODUCTION, but the
          trade frontier is about whether a location TRADES. Producing cotton
          does not mean exporting it. Prices separate the two: inside the
          frontier a location's price is tied to the world price net of freight,
                ln P_gl = ln P_g* - tau_g * t_l,
          so the price gradient in travel time is steeper for transport-cost-
          sensitive (high tau_g) goods. Beyond the frontier the location does
          not export, its price is set locally, and the tau_g ordering in prices
          should VANISH.

          Local price is the PAM implied unit value, value_prod / quantity.

          Tests:
          (A) Cardinal tau. Pooled traded crops, product + state FE: the
              sensitive-vs-insensitive difference in the travel-time gradient
              estimates tau_sensitive - tau_insensitive. Also validates the
              category_ex5 classification against a source independent of
              FAOSTAT EX_g.
          (B) Frontier, nonparametric. Sensitive-differential price gap by
              travel-time quintile. Inside the frontier the gap widens with t;
              beyond it, it flattens. The kink locates t-bar.
          (C) Frontier, parametric. Grid search over a threshold c splitting the
              sensitive gradient into an inside and an outside slope; t-bar is
              the SSR-minimising c. Prediction: inside slope < 0, outside ~ 0.
          (D) Does the frontier move inland over 1974 -> 1991 -> 2010, as roads
              improve and the trade regime liberalises (Prop 4)?

CAVEATS:  (i) Prices are observed only where the crop is grown, so the sample is
          endogenous to the very margin being tested. Coverage is reported.
          (ii) Unit values embed quality composition, not price alone.
          (iii) Nominal values are not comparable across years (hyperinflation,
          currency changes). Every specification is WITHIN year; across years we
          compare the location of the break in t, not price levels.
          (iv) Threshold inference is nonstandard; the equality test at the
          estimated c is indicative, and the nonparametric bins in (B) are the
          honest headline.

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   displayed estimates, $tables\price_frontier.png,
          $temp\price_gradient_bins.dta

RESULT (run 2026-07-28):
  (A) WORKS for 1974. Sensitive-vs-insensitive gradient -0.0504 per 100 hours
      (p = 0.051; -0.0587, p = 0.029 in logs). Gives a cardinal estimate of
      tau_sensitive - tau_insensitive and corroborates category_ex5 on a price
      margin. The shelf-life proxy is same-signed but insignificant in the
      model-correct levels spec (-0.0139, p = 0.226), so it is NOT independent
      confirmation; do not report it as such.
  (B) 1974 bins broadly declining, driven by the remote quintile (-0.146,
      p = 0.012). 1991 and 2010 non-monotone.
  (C) FRONTIER TEST NULL. No break in any year; b_in = b_out with p = 0.93 /
      0.44 / 0.90. Treat as underpowered rather than decisive: the split halves
      each side and se ~ 0.036 is the same order as the effect. Structural
      limit: prices exist only where the crop is grown, so the beyond-frontier
      region is exactly where the sample is thinnest and most selected.
  (D) Gradient REVERSES by 2010: +0.0756 (p = 0.019) levels, +0.0639 (p = 0.047)
      logs, +0.0403 (p = 0.020) shelf-life. Robust across three specs. Likely
      composition: 2010 "sensitive" is large-scale Cerrado soy, while what
      remains near ports is residual smallholder cotton.
==============================================================================*/

global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input "$root\01. Raw Data"
global tables "$root\05. Tables and Figures"
global temp "$root\02. Cleaning\temp"
global output "$root\03. Final Datasets"

*----------------- Setup: build the farmgate price panel ----------------------*

import delimited "$input\freight\product_class.csv", clear varnames(1) encoding(utf-8)
keep product category_ex5 shelf_life_days
* shelf_life_days carries "NA" for pasture, so it imports as a string
capture confirm string variable shelf_life_days
if _rc == 0 destring shelf_life_days, replace force
tempfile class
save `class'

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(3) nogen

* Implied farmgate unit value. Requires both quantity and value to be positive.
keep if quantity > 0 & value_prod > 0 & !missing(quantity) & !missing(value_prod)
gen luv = ln(value_prod / quantity)

merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf fm1970 fm1990 fm2010 fmpnv lat lon area)

* Contemporaneous travel time: the price gradient in year y reflects year-y
* trade costs. micro.dta carries 1970 / 1990 / 2010 travel times only, so the
* price tests use 1974, 1991 and 2010.
* The model is P_gl = P_g* / delta_g with delta_g = exp(tau_g * t), so
*     ln P_gl = ln P_g* - tau_g * t_l
* is linear in the LEVEL of travel time, not in its log. tt (hundreds of hours)
* is therefore the correct regressor and its coefficient is a semi-elasticity
* that maps directly to tau_g. lfm is retained only as a robustness check.
gen tt = .
replace tt = fm1970/100 if year == 1974
replace tt = fm1990/100 if year == 1991
replace tt = fm2010/100 if year == 2010
gen lfm = ln(tt*100)
keep if inlist(year, 1974, 1991, 2010) & !missing(tt)

gen traded = inlist(category_ex5, "exp_sensitive", "exp_insensitive")
gen sens   = category_ex5 == "exp_sensitive"
encode product, gen(prod_id)

di as result "=== Price-panel coverage (priced micro-region x crop cells) ==="
table year, statistic(frequency) statistic(sum traded)
di as result "  traded-crop cells by year, and micro-regions covered:"
foreach y in 1974 1991 2010 {
    quietly count if year == `y' & traded
    local n = r(N)
    quietly levelsof micro if year == `y' & traded, local(ms)
    di as result "    `y': " %5.0f `n' " cells, " %4.0f `: word count `ms'' " micro-regions"
}

*----------------- (A) Cardinal tau: the differenced price gradient -----------*

di as result ""
di as result "===A Sensitive-vs-insensitive travel-time gradient in ln(price)"
di as result "    Model: d ln P_g / d t = -tau_g, so the differential estimates"
di as result "    -(tau_sensitive - tau_insensitive), per 100 hours. Prod+state FE."
di as result "    year   insens slope   sens differential      p        N"

foreach y in 1974 1991 2010 {
    quietly reg luv c.tt##c.sens lat lon i.prod_id i.uf if year == `y' & traded, ///
        cluster(micro)
    local b0 = _b[tt]
    local bd = _b[c.tt#c.sens]
    local pd = 2*ttail(e(df_r), abs(_b[c.tt#c.sens]/_se[c.tt#c.sens]))
    di as result "    `y'   " %8.4f `b0' "      " %8.4f `bd' ///
        "        " %5.3f `pd' "   " %5.0f e(N)
}

di as result ""
di as result "  Robustness, log travel time (constant-elasticity, NOT the model):"
foreach y in 1974 1991 2010 {
    quietly reg luv c.lfm##c.sens lat lon i.prod_id i.uf if year == `y' & traded, ///
        cluster(micro)
    di as result "    `y': " %8.4f _b[c.lfm#c.sens] "  (p = " ///
        %5.3f (2*ttail(e(df_r), abs(_b[c.lfm#c.sens]/_se[c.lfm#c.sens]))) ")"
}

* Robustness: shelf life as a tau proxy independent of prices. The category
* split is built partly from value per ton, which is the same underlying
* variable as the outcome here; shelf life is not.
di as result ""
di as result "  Robustness, tau proxied by -ln(shelf life) instead of the category:"
gen nlshelf = -ln(shelf_life_days) if shelf_life_days > 0
quietly sum nlshelf if year == 1974 & traded
quietly replace nlshelf = (nlshelf - r(mean))/r(sd)
foreach y in 1974 1991 2010 {
    quietly reg luv c.tt##c.nlshelf lat lon i.prod_id i.uf ///
        if year == `y' & traded, cluster(micro)
    local bd = _b[c.tt#c.nlshelf]
    local pd = 2*ttail(e(df_r), abs(_b[c.tt#c.nlshelf]/_se[c.tt#c.nlshelf]))
    di as result "    `y': " %8.4f `bd' "  (p = " %5.3f `pd' ", N = " %5.0f e(N) ")"
}

*----------------- (B) Frontier, nonparametric: gap by travel-time bin --------*

di as result ""
di as result "===B Sensitive price gap by travel-time quintile (bin 1 = base)"
di as result "    Inside the frontier the gap widens (more negative) with t."
di as result "    Beyond it, no export margin, so the gap should flatten."

tempfile bins
postfile ph int year int bin double(mtt coef se lo hi) int nobs using `bins', replace

foreach y in 1974 1991 2010 {
    preserve
        quietly keep if year == `y' & traded
        quietly xtile bin = tt, nq(5)
        forvalues b = 2/5 {
            quietly gen sb`b' = (bin == `b') * sens
        }
        quietly reg luv i.bin sb2 sb3 sb4 sb5 lat lon i.prod_id i.uf, cluster(micro)
        di as result "    --- `y' (N = " e(N) ") ---"
        * bin 1 is the normalisation: coefficient 0 by construction
        quietly sum tt if bin == 1
        local m1 = r(mean)*100
        quietly count if bin == 1
        post ph (`y') (1) (`m1') (0) (0) (0) (0) (r(N))
        di as result "      bin 1 (mean TT " %6.1f `m1' "h):   0.0000  (base)"
        forvalues b = 2/5 {
            quietly sum tt if bin == `b'
            local mb = r(mean)*100
            local co = _b[sb`b']
            local se = _se[sb`b']
            local p  = 2*ttail(e(df_r), abs(`co'/`se'))
            quietly count if bin == `b'
            local nb = r(N)
            post ph (`y') (`b') (`mb') (`co') (`se') (`co'-1.96*`se') ///
                (`co'+1.96*`se') (`nb')
            di as result "      bin `b' (mean TT " %6.1f `mb' "h): " %8.4f `co' ///
                "  (se " %6.4f `se' ", p " %5.3f `p' ", n " %4.0f `nb' ")"
        }
    restore
}
postclose ph

*----------------- (C) Frontier, parametric: threshold grid search ------------*

di as result ""
di as result "===C Threshold search: sensitive gradient split at c"
di as result "    luv = prodFE + ufFE + b_in*sens*t*1{t<=c} + b_out*sens*t*1{t>c}"
di as result "    Prediction: b_in < 0 (price tied to world market), b_out ~ 0."

foreach y in 1974 1991 2010 {
    preserve
        quietly keep if year == `y' & traded
        * grid over the interior of the travel-time distribution
        quietly _pctile tt, p(20 80)
        local lo = r(r1)
        local hi = r(r2)
        local best = .
        local bestc = .
        local steps = 25
        forvalues i = 0/`steps' {
            local c = `lo' + (`hi' - `lo') * `i' / `steps'
            quietly gen byte open = tt <= `c'
            quietly gen s_in  = sens * tt * open
            quietly gen s_out = sens * tt * (1 - open)
            quietly gen s_lev = sens * (1 - open)
            capture quietly reg luv tt s_in s_out s_lev lat lon ///
                i.prod_id i.uf, cluster(micro)
            if _rc == 0 {
                if `best' == . | e(rss) < `best' {
                    local best = e(rss)
                    local bestc = `c'
                }
            }
            quietly drop open s_in s_out s_lev
        }
        * re-estimate at the SSR-minimising threshold
        quietly gen byte open = tt <= `bestc'
        quietly gen s_in  = sens * tt * open
        quietly gen s_out = sens * tt * (1 - open)
        quietly gen s_lev = sens * (1 - open)
        quietly reg luv tt s_in s_out s_lev lat lon i.prod_id i.uf, cluster(micro)
        quietly count if open
        local nin = r(N)
        di as result "    --- `y' ---"
        di as result "      t-bar (SSR-min)  = " %6.1f `bestc'*100 " hours"
        di as result "      share inside     = " %5.3f `nin'/e(N)
        di as result "      b_in  (t <= c)   = " %8.4f _b[s_in] ///
            "  (p = " %5.3f (2*ttail(e(df_r), abs(_b[s_in]/_se[s_in]))) ")"
        di as result "      b_out (t >  c)   = " %8.4f _b[s_out] ///
            "  (p = " %5.3f (2*ttail(e(df_r), abs(_b[s_out]/_se[s_out]))) ")"
        quietly test s_in = s_out
        di as result "      H0: b_in = b_out -> F = " %6.2f r(F) ///
            ", p = " %5.3f r(p) "  (nonstandard, indicative only)"
    restore
}

*----------------- (D) Figure: the gap profile, and whether it moves ----------*

use `bins', clear
save "$temp\price_gradient_bins.dta", replace

gen ltt = ln(mtt)
label var mtt "Mean travel time to port (hours)"

twoway ///
    (rcap lo hi mtt if year == 1974, lcolor(navy%40)) ///
    (connected coef mtt if year == 1974, lcolor(navy) mcolor(navy) msymbol(O)) ///
    (rcap lo hi mtt if year == 1991, lcolor(cranberry%40)) ///
    (connected coef mtt if year == 1991, lcolor(cranberry) mcolor(cranberry) msymbol(S)) ///
    (rcap lo hi mtt if year == 2010, lcolor(dkgreen%40)) ///
    (connected coef mtt if year == 2010, lcolor(dkgreen) mcolor(dkgreen) msymbol(T)) ///
    , yline(0, lcolor(gs8) lpattern(dash)) ///
      xlabel(0(50)300) ///
      xtitle("Mean travel time to port (hours)") ///
      ytitle("Sensitive-vs-insensitive log price gap" "relative to the most accessible quintile") ///
      legend(order(2 "1974" 4 "1991" 6 "2010") ring(0) pos(7) cols(1) ///
             region(lstyle(none))) ///
      note("Farmgate unit values from PAM. Product and state fixed effects;" ///
           "standard errors clustered on micro-region. A declining profile is the" ///
           "world-price link; a flat segment is beyond the trade frontier.") ///
      graphregion(color(white)) plotregion(color(white))

graph export "$tables\price_frontier.png", replace width(2200)
di as result ""
di as result "Figure written to $tables\price_frontier.png"
