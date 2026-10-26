/*==============================================================================
PURPOSE:  Replicate Coşar-Fajgelbaum (2016, AEJ:Micro) empirical design on the
          Brazilian data, table by table.

          IMPORTANT FINDING FROM READING CF: they never test the trade frontier
          directly. They estimate no threshold, locate no t-bar, and look for no
          discontinuity between the coastal and autarkic interior regions. Their
          conclusion claims only that "comparative-advantage industries at the
          national level locate closer to international gates." What they test
          is the SPECIALIZATION GRADIENT the frontier model implies, via

              Y_ip = b*Z_ip + theta * Distance_p x ExportOrientation_i     (23)

          with industry and prefecture FE, clustered on prefecture. That is
          already what 10.pooled_tau does, so the thesis headline is the
          CF-faithful test. This file adds the three CF tables the thesis has
          NOT done.

          Correspondence of measures:
            CF Distance_p (miles to coast)  -> travel time to port
            CF CNXR_i (export/revenue)      -> ex_mean from FAOSTAT (ex_ratio.csv)
            CF USLK_i (exogenous 2nd proxy) -> -ln(value per ton), and shelf life

          Tables:
          (1) CF Table 1, intensive margin. ln(area) and ln(quantity) on
              Distance x EX, positive cells only, product + micro FE.
          (2) CF Table 2, EXTENSIVE margin. 1{area>0} on Distance x EX by LPM
              with both FE, probit, and conditional logit. This is the test
              08.frontier_tests_hump.do should have run: CF keep the binary at
              the INDUSTRY x PREFECTURE cell, whereas 08 collapsed to a
              region-level max over crops and destroyed the variation (84.8% of
              micro-regions had some sensitive crop, only 10 of 531 entered).
              At the cell level 75% of traded cells are zero, comparable to
              CF's 58%.
          (3) CF Table 3, time variation. Panel with product x micro FE plus
              product x year and micro x year FE, so identification is within
              cell over time.
          (4) CF Table 4, alternative mechanism: local productivity. CF argue
              that if fundamentals or externalities drove the pattern, relative
              productivity in export-oriented sectors would fall with distance.
              The Brazilian analogue is YIELD (quantity/area). This turns the
              paper's "levels puzzle" (sensitive crops sit inland, blamed on
              Cerrado suitability) from an assertion into a measurement.

INPUT:    $temp\landshare_micro.dta, $output\micro.dta,
          $input\freight\product_class.csv, $input\faostat\ex_ratio.csv
OUTPUT:   displayed estimates

RESULT (run 2026-07-28). 95,580 product x micro x year cells, 60 products with
an EX ratio, 31.8% of cells with positive area (CF's China: 42%).

(1) Intensive margin, log distance: null in all years (-0.021 / -0.044 / -0.007).
    In distance LEVELS, 1974 ln(area) is -0.0723 (p < 0.001), i.e. CF's sign.
(2) Extensive margin, LPM with both FE. The two proxies DISAGREE, which is the
    exact situation CF's two-proxy strategy is designed for:
      EX ratio (their CNXR): -0.0005 (p=0.81) / +0.0139 (p<0.001) / +0.0087
        (p<0.001) -- wrong sign in 1991 and 2010.
      shelf life (their USLK, exogenous): -0.0179 / -0.0183 / -0.0101, all
        p <= 0.003 -- CF's sign in every year.
    EX_g is endogenous to the phenomenon (Cerrado soy expansion is WHY Brazil
    became a soy exporter); shelf life is a physical characteristic and is not.
    CF raise precisely this concern for China.
    1974 clogit, when run, agrees with the LPM null: -0.0015 (p = 0.941).
(3) Within-cell time variation (prod x micro, prod x year, micro x year FE) --
    CF's most demanding design. Extensive margin -0.0332 (se 0.0086, p < 0.001,
    N = 95,580): CF's sign and significance. ln(quantity) -0.190 (p = 0.084),
    ln(area) -0.038 (p = 0.72). So the cross-sectional wrong sign flips to the
    predicted sign once location fundamentals are differenced out -- the thesis's
    own "levels = puzzle, changes = test" decision, now shown inside CF's design.
(4) Yield (CF's fundamentals check; theta < 0 means fundamentals are operative):
    1974 -0.0186 (p=0.008), 1991 +0.0055 (p=0.49), 2010 +0.0294 (p<0.001),
    within-cell -0.1527 (p<0.001). The 2010 POSITIVE says export-oriented crops
    are genuinely more productive inland by 2010 -- the Cerrado-suitability story
    the paper asserts for the levels puzzle, now measured. Caveat: within-cell,
    yield may respond endogenously to market access via input intensification,
    so the panel coefficient is not a clean fundamentals measure.

KEY METHOD LESSON: CF hold the binary at the INDUSTRY x PREFECTURE cell.
08.frontier_tests_hump.do collapsed to a region-level max over crops, which is
what made the outcome degenerate (84.8% baseline, 10 entrants of 531). At the
cell level the same data has 31.8% positive and ample variation.
==============================================================================*/

global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input "$root\01. Raw Data"
global tables "$root\05. Tables and Figures"
global temp "$root\02. Cleaning\temp"
global output "$root\03. Final Datasets"

*----------------- Setup ------------------------------------------------------*

import delimited "$input\freight\product_class.csv", clear varnames(1) encoding(utf-8)
keep product category_ex5 shelf_life_days
capture confirm string variable shelf_life_days
if _rc == 0 destring shelf_life_days, replace force
tempfile class
save `class'

import delimited "$input\faostat\ex_ratio.csv", clear varnames(1) encoding(utf-8)
keep product ex_mean ex_7089 ex_9010
tempfile ex
save `ex'

use "$temp\landshare_micro.dta", clear
merge m:1 product using `class', keep(1 3) nogen
merge m:1 product using `ex', keep(1 3) nogen

merge m:1 micro using "$output\micro.dta", keep(3) nogen ///
    keepusing(uf fm1970 fm1990 fm2010 fmpnv lat lon area)

keep if inlist(year, 1974, 1991, 2010)

* Distance: contemporaneous travel time to port. Primary measure in logs, to
* stay consistent with the rest of the thesis; levels reported as robustness.
gen tt = .
replace tt = fm1970/100 if year == 1974
replace tt = fm1990/100 if year == 1991
replace tt = fm2010/100 if year == 2010
gen dist  = ln(tt*100)
gen larea = ln(area)

* Export orientation. CF standardise nothing but discuss 1-sd effects; we
* standardise so the interaction reads directly as a per-sd effect.
quietly sum ex_mean
gen ex = (ex_mean - r(mean))/r(sd)

* Second, price-independent proxy for tau: shelf life (CF use US labour
* intensity precisely because it is not generated by the outcome data).
gen tau_shelf = -ln(shelf_life_days) if shelf_life_days > 0
quietly sum tau_shelf
replace tau_shelf = (tau_shelf - r(mean))/r(sd)

gen pos    = area_ha > 0 & !missing(area_ha)
gen larea_c = ln(area_ha) if pos
gen lqty    = ln(quantity) if quantity > 0 & !missing(quantity)
gen lyield  = ln(quantity/area_ha) if quantity > 0 & area_ha > 0 & !missing(quantity)
encode product, gen(prod_id)
egen cell = group(prod_id micro)

drop if missing(ex)

di as result "=== Sample ==="
count
di as result "  product x micro x year cells: " r(N)
quietly levelsof prod_id, local(ps)
di as result "  products with an EX ratio: " `: word count `ps''
quietly sum pos
di as result "  share of cells with positive area: " %5.3f r(mean) ///
    "   (CF's Chinese analogue: 0.42 positive, 58% zero)"

*----------------- (1) CF Table 1: intensive margin ---------------------------*

di as result ""
di as result "===1 CF Table 1 analogue - INTENSIVE margin (positive cells only)"
di as result "    Y = b*Z + theta * Distance x ExportOrientation, prod + micro FE"
di as result "    CF find theta < 0: export-oriented industries shrink inland."
di as result "    outcome        year   theta(dist x EX)     se       p       N"

foreach y in 1974 1991 2010 {
    foreach v in larea_c lqty {
        quietly reghdfe `v' c.dist#c.ex if year == `y', ///
            absorb(prod_id micro) vce(cluster micro)
        di as result "    " %-12s "`v'" "  `y'   " %10.4f _b[c.dist#c.ex] ///
            "   " %7.4f _se[c.dist#c.ex] "  " %5.3f ///
            (2*ttail(e(df_r), abs(_b[c.dist#c.ex]/_se[c.dist#c.ex]))) ///
            "  " %6.0f e(N)
    }
}

*----------------- (2) CF Table 2: EXTENSIVE margin ---------------------------*

di as result ""
di as result "===2 CF Table 2 analogue - EXTENSIVE margin, 1{area > 0}"
di as result "    This is the cell-level test. CF: Distance x CNXR is negative"
di as result "    and highly significant (LPM -0.010, probit -0.066)."
di as result ""
di as result "    (a) LPM with product and micro FE (CF column 4):"
di as result "        year    theta       se       p        N"
foreach y in 1974 1991 2010 {
    quietly reghdfe pos c.dist#c.ex if year == `y', ///
        absorb(prod_id micro) vce(cluster micro)
    di as result "        `y'  " %8.4f _b[c.dist#c.ex] "  " %7.4f _se[c.dist#c.ex] ///
        "  " %5.3f (2*ttail(e(df_r), abs(_b[c.dist#c.ex]/_se[c.dist#c.ex]))) ///
        "  " %6.0f e(N)
}

di as result ""
di as result "    (b) Probit, product FE, clustered on micro (CF column 1):"
foreach y in 1974 1991 2010 {
    quietly probit pos c.dist#c.ex dist i.prod_id if year == `y', vce(cluster micro)
    di as result "        `y'  " %8.4f _b[c.dist#c.ex] "  " %7.4f _se[c.dist#c.ex] ///
        "  " %5.3f (2*normal(-abs(_b[c.dist#c.ex]/_se[c.dist#c.ex]))) ///
        "  " %6.0f e(N)
}

* (c) CF's conditional-logit columns 2-3 are skipped by default: with 531 groups
* and 60 product dummies clogit runs for well over ten minutes per year, and the
* LPM above is CF's own preferred both-FE specification (their column 4). The
* 1974 clogit, when run, gives -0.0015 (se 0.0203, p = 0.941), i.e. the same
* null as the LPM. Set cf_clogit to 1 to run all three years.
global cf_clogit 0
if $cf_clogit {
    di as result ""
    di as result "    (c) Conditional logit grouped on micro (CF columns 2-3):"
    foreach y in 1974 1991 2010 {
        capture quietly clogit pos c.dist#c.ex i.prod_id if year == `y', ///
            group(micro) vce(cluster micro)
        if _rc == 0 {
            di as result "        `y'  " %8.4f _b[c.dist#c.ex] "  " ///
                %7.4f _se[c.dist#c.ex] "  " %5.3f ///
                (2*normal(-abs(_b[c.dist#c.ex]/_se[c.dist#c.ex]))) "  " %6.0f e(N)
        }
        else di as result "        `y'  clogit failed (rc = " _rc ")"
    }
}

di as result ""
di as result "    (d) Same LPM with the price-independent proxy (shelf life):"
foreach y in 1974 1991 2010 {
    quietly reghdfe pos c.dist#c.tau_shelf if year == `y', ///
        absorb(prod_id micro) vce(cluster micro)
    di as result "        `y'  " %8.4f _b[c.dist#c.tau_shelf] "  " ///
        %7.4f _se[c.dist#c.tau_shelf] "  " %5.3f ///
        (2*ttail(e(df_r), abs(_b[c.dist#c.tau_shelf]/_se[c.dist#c.tau_shelf]))) ///
        "  " %6.0f e(N)
}

*----------------- (3) CF Table 3: time variation -----------------------------*

di as result ""
di as result "===3 CF Table 3 analogue - within-cell time variation"
di as result "    product x micro FE, plus product x year and micro x year FE."
di as result "    CF: coefficient stays negative, so the result is not purely"
di as result "    cross-sectional."

egen py = group(prod_id year)
egen my = group(micro year)

foreach v in pos larea_c lqty {
    quietly reghdfe `v' c.dist#c.ex, absorb(cell py my) vce(cluster micro)
    di as result "    " %-10s "`v'" "  theta = " %8.4f _b[c.dist#c.ex] ///
        "  (se " %6.4f _se[c.dist#c.ex] ", p " %5.3f ///
        (2*ttail(e(df_r), abs(_b[c.dist#c.ex]/_se[c.dist#c.ex]))) ///
        ", N " %6.0f e(N) ")"
}

* CF also exploit that industries whose export orientation ROSE should move
* toward the coast. ex_7089 vs ex_9010 gives the Brazilian analogue.
gen ex_t = ex_7089 if year == 1974
replace ex_t = ex_9010 if inlist(year, 1991, 2010)
quietly sum ex_t
replace ex_t = (ex_t - r(mean))/r(sd)
di as result "    Using period-specific EX (1970-89 vs 1990-2010):"
foreach v in pos larea_c {
    quietly reghdfe `v' c.dist#c.ex_t, absorb(cell py my) vce(cluster micro)
    di as result "    " %-10s "`v'" "  theta = " %8.4f _b[c.dist#c.ex_t] ///
        "  (se " %6.4f _se[c.dist#c.ex_t] ", p " %5.3f ///
        (2*ttail(e(df_r), abs(_b[c.dist#c.ex_t]/_se[c.dist#c.ex_t]))) ")"
}

*----------------- (4) CF Table 4: is it land fundamentals? -------------------*

di as result ""
di as result "===4 CF Table 4 analogue - LOCAL PRODUCTIVITY (yield)"
di as result "    CF's logic: if fundamentals or externalities drove the"
di as result "    specialization pattern, relative productivity in export-"
di as result "    oriented sectors would FALL with distance (theta < 0)."
di as result "    Brazil's analogue is yield = quantity/area. A POSITIVE theta"
di as result "    means export-oriented crops are relatively MORE productive"
di as result "    inland - i.e. the Cerrado-suitability story the paper invokes"
di as result "    for the levels puzzle, now measured rather than asserted."
di as result "        year   theta(dist x EX)     se       p        N"
foreach y in 1974 1991 2010 {
    quietly reghdfe lyield c.dist#c.ex if year == `y', ///
        absorb(prod_id micro) vce(cluster micro)
    di as result "        `y'  " %10.4f _b[c.dist#c.ex] "   " %7.4f _se[c.dist#c.ex] ///
        "  " %5.3f (2*ttail(e(df_r), abs(_b[c.dist#c.ex]/_se[c.dist#c.ex]))) ///
        "  " %6.0f e(N)
}
di as result "    Within-cell over time:"
quietly reghdfe lyield c.dist#c.ex, absorb(cell py my) vce(cluster micro)
di as result "        theta = " %8.4f _b[c.dist#c.ex] "  (se " %6.4f _se[c.dist#c.ex] ///
    ", p " %5.3f (2*ttail(e(df_r), abs(_b[c.dist#c.ex]/_se[c.dist#c.ex]))) ")"

*----------------- Robustness: distance in levels, as CF measure it -----------*

di as result ""
di as result "===5 Robustness: distance in hundreds of hours (CF use 100 miles)"
foreach v in pos larea_c lyield {
    quietly reghdfe `v' c.tt#c.ex if year == 1974, ///
        absorb(prod_id micro) vce(cluster micro)
    di as result "    1974 " %-10s "`v'" "  theta = " %8.4f _b[c.tt#c.ex] ///
        "  (p " %5.3f (2*ttail(e(df_r), abs(_b[c.tt#c.ex]/_se[c.tt#c.ex]))) ")"
}
