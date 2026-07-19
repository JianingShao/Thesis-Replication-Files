/*==============================================================================
PURPOSE:  Test the specialization proposition: land shares reallocate toward
          transport-cost-sensitive goods where travel time falls, with
          good-specific elasticities ordered by transport-cost sensitivity.

          For each product g, estimate:
          (RF)  D.landshare_g on PIN-induced reduction in log travel time
          (IV)  D.landshare_g on actual reduction, instrumented by PIN
          (PPML) landshare_g,2010 on log travel time 2010 (FR 2022, Table 5)
          Then correlate the estimated gradients with product unit values
          (value per unit of output), an inverse proxy for transport-cost
          sensitivity: cheap-per-ton goods are transport-cost-sensitive, so
          their land shares should respond more to travel-time reductions.

INPUT:    $temp\landshare_micro.dta        (from 08.landshare.do)
          $output\micro.dta                (travel times and controls)
OUTPUT:   $tables\landshare\landshare_phi.csv
          $tables\landshare\phi_unitvalue.png
==============================================================================*/

global tables "$root\05. Tables and Figures"
capture mkdir "$tables\landshare"

*----------------- 1. Build inputs -------------------------------------------*

* Micro-level treatment and controls
use "$output\micro.dta", clear
keep micro uf fm1970 fm2010 fmpnv lat lon area
gen dltt_actual = ln(fm1970) - ln(fm2010)
gen dltt_pin    = ln(fm1970) - ln(fmpnv)
gen lfm2010     = ln(fm2010)
gen larea       = ln(area)
label var dltt_actual "Actual reduction in log travel time, 1970-2010"
label var dltt_pin    "PIN-induced reduction in log travel time"
tempfile treat
save `treat'

* Land shares, 1974 and 2010 cross-sections
use "$temp\landshare_micro.dta", clear
keep if inlist(year, 1974, 2010)
keep micro year product landshare area_ha quantity value_prod
tempfile shares
save `shares'

* National unit values in 2010 (value per unit of output, current mil reais)
use `shares' if year == 2010, clear
collapse (sum) quantity value_prod, by(product)
gen unitval = value_prod / quantity
keep product unitval
tempfile uv
save `uv'

*----------------- 2. Per-product regressions --------------------------------*

use `shares', clear
levelsof product, local(prods)

tempname results
postfile `results' str120 product n_pos ///
    beta_rf se_rf beta_iv se_iv phi_pois se_pois ///
    using "$temp\landshare_phi.dta", replace

foreach p of local prods {
    quietly {
        use `shares' if product == `"`p'"', clear
        keep micro year landshare
        reshape wide landshare, i(micro) j(year)
        * Product absent from the 1974 classification: land share was zero
        replace landshare1974 = 0 if missing(landshare1974)
        merge 1:1 micro using `treat', keep(3) nogen

        count if landshare2010 > 0 & !missing(landshare2010)
        local npos = r(N)
        gen dshare = landshare2010 - landshare1974

        * Reduced form on the PIN instrument
        capture reg dshare dltt_pin landshare1974 lat lon larea i.uf, ///
            cluster(uf)
        if !_rc {
            local brf = _b[dltt_pin]
            local srf = _se[dltt_pin]
        }
        else {
            local brf = .
            local srf = .
        }

        * IV: actual reduction instrumented by PIN
        capture ivregress 2sls dshare ///
            (dltt_actual = dltt_pin) landshare1974 lat lon larea i.uf, ///
            cluster(uf)
        if !_rc {
            local biv = _b[dltt_actual]
            local siv = _se[dltt_actual]
        }
        else {
            local biv = .
            local siv = .
        }

        * FR-style cross-sectional PPML gradient in 2010
        capture poisson landshare2010 lfm2010 lat lon larea i.uf, ///
            cluster(uf) iterate(50)
        if !_rc & e(converged) == 1 {
            local bpo = _b[lfm2010]
            local spo = _se[lfm2010]
        }
        else {
            local bpo = .
            local spo = .
        }

        post `results' (`"`p'"') (`npos') ///
            (`brf') (`srf') (`biv') (`siv') (`bpo') (`spo')
    }
}
postclose `results'

*----------------- 3. Gradients vs. transport-cost sensitivity ---------------*

use "$temp\landshare_phi.dta", clear
merge 1:1 product using `uv', nogen
gen luv = ln(unitval)
label var luv "Log unit value 2010 (inverse transport-sensitivity proxy)"

* Restrict to products grown in at least 50 micro-regions in 2010
keep if n_pos >= 50

di as result "=== products in test sample: " _N

* Model prediction: transport-sensitive (low unit value) goods gain land share
* where travel time falls, so beta should DECREASE with unit value and the
* PPML travel-time gradient phi should INCREASE with unit value
corr beta_iv luv
di as result "=== corr(beta_iv, log unit value): " %6.3f r(rho)
spearman beta_iv luv
di as result "=== spearman(beta_iv, log unit value): " %6.3f r(rho) ///
    " p = " %5.3f r(p)
corr phi_pois luv
di as result "=== corr(phi_ppml, log unit value): " %6.3f r(rho)
spearman phi_pois luv
di as result "=== spearman(phi_ppml, log unit value): " %6.3f r(rho) ///
    " p = " %5.3f r(p)

export delimited using "$tables\landshare\landshare_phi.csv", replace

* Scatter: IV gradient against log unit value
twoway (scatter beta_iv luv, mlabel(product) mlabsize(tiny)) ///
       (lfit beta_iv luv), ///
    xtitle("Log unit value, 2010") ///
    ytitle("IV land-share response to travel-time reduction") ///
    legend(off)
graph export "$tables\landshare\phi_unitvalue.png", replace width(2000)
