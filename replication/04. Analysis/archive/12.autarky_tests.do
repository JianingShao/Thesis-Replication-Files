/*==============================================================================
PURPOSE:  Test the empirical implications of specifying AUTARKY PRICES beyond
          the trade frontier.

          With P_gl = max{P_g* exp(-tau_g t_l), P_gl^A} and the autarky price
          P_gl^A = (z_M / Gamma^alpha) (gamma_g / T_gl)^(1/theta) independent of
          t_l, market clearing in a closed location forces the land share to the
          within-agriculture consumption share:
                l_gl = gamma_g / gamma_A  for t_l beyond the frontier.
          Three regimes follow:
            fully open      d ln l_g/dt = -theta (tau_g - taubar_l)
            partially open  exported goods fall, non-exported rise
            fully closed    d ln l_g/dt = 0, shares common across locations

          Tests:
          (1) DISPERSION. Closed locations share a common share vector, so the
              cross-location dispersion of the crop-share vector must FALL with
              travel time. Sharpest single implication.
          (2) PER-CROP KINK. Each good closes at its own t_g, so the share
              profile kinks; the kinks must be ORDERED by tau_g (high tau closes
              first / nearer). Rank correlation of kink location with value per
              ton, which is an inverse tau proxy, must be POSITIVE.
          (3) DOMESTIC CROPS ARE NOT A PLACEBO. Where locations are partially
              open, exported goods lose land and non-exported goods gain, so the
              domestic-crop gradient must exceed the traded-crop gradient.
          (4) COMPRESSION. taubar_l falls as goods close, so the pooled tau
              interaction of 10.pooled_tau must SHRINK toward zero with
              remoteness.

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv
OUTPUT:   displayed estimates, $tables\autarky_dispersion.png,
          $temp\autarky_kinks.dta
==============================================================================*/

global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input "$root\01. Raw Data"
global tables "$root\05. Tables and Figures"
global temp "$root\02. Cleaning\temp"
global output "$root\03. Final Datasets"

capture which ivreghdfe
if _rc ssc install ivreghdfe, replace

import delimited "$input\freight\product_class.csv", clear varnames(1) encoding(utf-8)
keep product category_ex5
tempfile class
save `class'

* National value per ton: the inverse tau proxy, same construction as 10.pooled_tau
use "$temp\landshare_micro.dta", clear
keep if year == 2010
collapse (sum) value_prod quantity, by(product)
gen lnvpt = ln(1000 * value_prod / quantity)
keep product lnvpt
tempfile vpt
save `vpt'

*----------------- (1) DISPERSION of the crop-share vector --------------------*

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(3) nogen
keep if inlist(year, 1974, 1991, 2010)
* landshare_crops sums to one across crops within micro-year, so dispersion is
* not mechanically compressed by the level of agricultural activity
keep if !missing(landshare_crops)
merge m:1 micro using "$output\micro.dta", keep(3) nogen keepusing(fm1970 uf)
gen tt = fm1970/100

di as result "===1 Cross-location dispersion of the crop-share vector, by"
di as result "    travel-time quintile. Model: closed locations converge on"
di as result "    gamma_g/gamma_A, so dispersion must FALL with travel time."
di as result ""

tempfile disp
postfile dh int year int bin double(mtt totvar mpair) int nloc using `disp', replace

* Assign each micro-region to a travel-time quintile once, on the location
* cross-section rather than on the stacked product rows.
egen tag = tag(micro)
xtile bin = tt if tag, nq(5)
bysort micro (bin): replace bin = bin[1]

foreach y in 1974 1991 2010 {
    di as result "    --- `y' ---"
    forvalues b = 1/5 {
        preserve
            quietly keep if year == `y' & bin == `b'
            quietly egen tg = tag(micro)
            quietly count if tg
            local nloc = r(N)
            quietly sum tt if tg, meanonly
            local mtt = r(mean)*100
            * Var across locations of each crop's share, then summed over crops.
            * Mean pairwise squared distance between share vectors = 2 * that sum.
            quietly collapse (sd) sdg = landshare_crops, by(product)
            quietly replace sdg = sdg^2
            quietly sum sdg, meanonly
            local totvar = r(sum)
        restore
        local mpair = 2*`totvar'
        di as result "      Q`b' (mean TT " %6.1f `mtt' "h, n=" %3.0f `nloc' ///
            "): sum Var = " %8.5f `totvar' ///
            "   mean pairwise dist^2 = " %8.5f `mpair'
        post dh (`y') (`b') (`mtt') (`totvar') (`mpair') (`nloc')
    }
}
postclose dh

preserve
    use `disp', clear
    di as result ""
    di as result "  Spearman rank correlation of dispersion with quintile:"
    foreach y in 1974 1991 2010 {
        quietly spearman totvar bin if year == `y'
        di as result "    `y': rho = " %6.3f r(rho) "  (p = " %5.3f r(p) ")"
    }
    save "$temp\autarky_dispersion.dta", replace
    twoway (connected totvar mtt if year == 1974, lcolor(navy) mcolor(navy)) ///
           (connected totvar mtt if year == 1991, lcolor(cranberry) mcolor(cranberry) msymbol(S)) ///
           (connected totvar mtt if year == 2010, lcolor(dkgreen) mcolor(dkgreen) msymbol(T)) ///
        , xtitle("Mean travel time to port (hours)") ///
          ytitle("Cross-location dispersion of crop-share vector" "(sum of variances over crops)") ///
          legend(order(1 "1974" 2 "1991" 3 "2010") ring(0) pos(1) cols(1) region(lstyle(none))) ///
          note("Model predicts dispersion falls with travel time: closed locations" ///
               "share the common consumption-share vector gamma_g/gamma_A.") ///
          graphregion(color(white)) plotregion(color(white))
    graph export "$tables\autarky_dispersion.png", replace width(2000)
restore

*----------------- (2) PER-CROP KINK, ordered by tau --------------------------*

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(3) nogen
merge m:1 product using `vpt', keep(3) nogen
keep if inlist(category_ex5, "exp_sensitive", "exp_insensitive")
keep if year == 1974
merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(fm1970 uf lat lon)
gen tt    = fm1970/100
gen share = landshare_crops
replace share = 0 if missing(share)

di as result ""
di as result "===2 Per-crop kink in the share profile, and its ordering by tau."
di as result "    Model: each good closes at its own t_g with dt_g/dtau_g < 0,"
di as result "    so kinks must be ORDERED by value per ton (inverse tau)."
di as result "    Restricted to crops grown in at least 10% of micro-regions."
di as result ""
di as result "    crop                          prev   ln(v/t)   kink(h)   b_in      b_out"

tempfile kinks
postfile kh str40 prod double(prev lnvpt kink bin_ bout) using `kinks', replace

levelsof product, local(prods)
foreach p of local prods {
    preserve
        quietly keep if product == "`p'"
        quietly count if share > 0
        local prev = r(N)/_N
        quietly sum lnvpt, meanonly
        local lv = r(mean)
        if `prev' >= 0.10 {
            quietly _pctile tt, p(20 80)
            local lo = r(r1)
            local hi = r(r2)
            local best = .
            local bestc = .
            forvalues i = 0/25 {
                local c = `lo' + (`hi'-`lo')*`i'/25
                quietly gen double sp1 = min(tt, `c')
                quietly gen double sp2 = max(tt - `c', 0)
                capture quietly reg share sp1 sp2 lat lon i.uf
                if _rc == 0 {
                    if `best' == . | e(rss) < `best' {
                        local best  = e(rss)
                        local bestc = `c'
                    }
                }
                quietly drop sp1 sp2
            }
            quietly gen double sp1 = min(tt, `bestc')
            quietly gen double sp2 = max(tt - `bestc', 0)
            quietly reg share sp1 sp2 lat lon i.uf, robust
            local bi = _b[sp1]
            local bo = _b[sp2]
            di as result "    " %-28s substr("`p'",1,28) "  " %5.3f `prev' ///
                "  " %7.3f `lv' "  " %7.1f `bestc'*100 "  " %8.4f `bi' "  " %8.4f `bo'
            post kh ("`p'") (`prev') (`lv') (`bestc'*100) (`bi') (`bo')
        }
        else {
            di as result "    " %-28s substr("`p'",1,28) "  " %5.3f `prev' ///
                "   (skipped, prevalence < 10%)"
        }
    restore
}
postclose kh

preserve
    use `kinks', clear
    save "$temp\autarky_kinks.dta", replace
    di as result ""
    di as result "  Ordering test: kink location vs ln(value per ton)."
    di as result "  Model predicts POSITIVE (low tau = high value/ton closes further out)."
    quietly spearman kink lnvpt
    di as result "    Spearman rho = " %6.3f r(rho) "  (p = " %5.3f r(p) ", n = " %2.0f r(N) ")"
    quietly pwcorr kink lnvpt, sig
    di as result "    Pearson  r   = " %6.3f r(rho)
    di as result ""
    di as result "  Slope signs: model predicts b_in < 0 and b_out ~ 0."
    quietly count if bin_ < 0
    local nin = r(N)
    quietly count
    di as result "    b_in < 0 in " `nin' " of " r(N) " crops"
    quietly count if abs(bout) < abs(bin_)
    di as result "    |b_out| < |b_in| in " r(N) " of " _N " crops"
restore

*----------------- (3) DOMESTIC CROPS ARE NOT A PLACEBO ----------------------*

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(3) nogen
keep if inlist(year, 1974, 1991, 2010)
merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(fm1970 uf lat lon)
gen tt     = fm1970/100
gen share  = landshare_crops
replace share = 0 if missing(share)
gen traded = inlist(category_ex5, "exp_sensitive", "exp_insensitive")
gen domest = category_ex5 == "domestic"
keep if traded | domest
egen prodid = group(product)

di as result ""
di as result "===3 Traded vs domestic share gradient in travel time."
di as result "    Model: where locations are partially open, exported goods lose"
di as result "    land and non-exported goods gain, so the DIFFERENCE"
di as result "    (domestic - traded) must be POSITIVE."
di as result ""
di as result "    year    traded slope    domestic differential      p"

foreach y in 1974 1991 2010 {
    quietly reg share c.tt##i.domest lat lon i.prodid i.uf if year == `y', ///
        cluster(micro)
    local bt = _b[tt]
    local bd = _b[1.domest#c.tt]
    local pd = 2*ttail(e(df_r), abs(_b[1.domest#c.tt]/_se[1.domest#c.tt]))
    di as result "    `y'  " %10.5f `bt' "       " %10.5f `bd' ///
        "         " %5.3f `pd'
}

*----------------- (4) COMPRESSION of the pooled tau interaction --------------*

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
gen sens_dtt = sens * dtt_actual
gen sens_pin = sens * dtt_pin
gen vpt_dtt  = lnvpt * dtt_actual
gen vpt_pin  = lnvpt * dtt_pin

egen tag = tag(micro)
xtile terc = fm1970 if tag, nq(3)
bysort micro (terc): replace terc = terc[1]

di as result ""
di as result "===4 Pooled tau interaction by initial-remoteness tercile."
di as result "    Model: taubar_l falls as goods close, so the interaction must"
di as result "    COMPRESS toward zero with remoteness."
di as result ""
di as result "    Binary tau (sensitive x DTT), outcome D share:"
forvalues k = 1/3 {
    quietly sum fm1970 if terc == `k' & tag, meanonly
    local mt = r(mean)
    capture quietly ivreghdfe dshare (sens_dtt = sens_pin) if terc == `k', ///
        absorb(prodid micro) cluster(micro)
    if _rc == 0 {
        di as result "      T`k' (mean TT " %6.1f `mt' "h): " %9.5f _b[sens_dtt] ///
            "  (se " %8.5f _se[sens_dtt] ", p " ///
            %5.3f (2*normal(-abs(_b[sens_dtt]/_se[sens_dtt]))) ", N " %4.0f e(N) ")"
    }
}
di as result ""
di as result "    Continuous tau (ln value/ton x DTT), outcome D share:"
forvalues k = 1/3 {
    quietly sum fm1970 if terc == `k' & tag, meanonly
    local mt = r(mean)
    capture quietly ivreghdfe dshare (vpt_dtt = vpt_pin) if terc == `k', ///
        absorb(prodid micro) cluster(micro)
    if _rc == 0 {
        di as result "      T`k' (mean TT " %6.1f `mt' "h): " %9.5f _b[vpt_dtt] ///
            "  (se " %8.5f _se[vpt_dtt] ", p " ///
            %5.3f (2*normal(-abs(_b[vpt_dtt]/_se[vpt_dtt]))) ", N " %4.0f e(N) ")"
    }
}
