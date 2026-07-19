/*==============================================================================
PURPOSE:  Construct a product-level transport-cost sensitivity measure tau_g
          and test the specialization proposition across products: land-share
          responses to travel-time reductions (from 04.landshare.do) should be
          larger for more transport-cost-sensitive goods.

          tau_g has two domestic components, per hour of road transport:
          (i)  money cost  = trucking rate per ton-hour / value per ton,
               where the rate uses ANTT minimum-freight coefficients by cargo
               category (Tabela A, 6 axles; 32t payload; 60 km/h) and value
               per ton comes from PAM 2010 production values;
          (ii) spoilage    = 1 / (24 x shelf life in days), the fraction of
               the shipment lost per hour for perishables.

          Identifying assumption: the cross-product RANKING of tau_g is
          stable over 1974-2010 (rates are 2026, values are 2010).

INPUT:    $input\freight\product_class.csv     (cargo category, shelf life)
          $input\freight\antt_rates.csv        (ANTT coefficients, source)
          $temp\landshare_micro.dta            (for value per ton, 2010)
          $temp\landshare_phi.dta              (per-product gradients)
OUTPUT:   $tables\landshare\tau_test.csv
          $tables\landshare\beta_tau.png
==============================================================================*/

global tables "$root\05. Tables and Figures"
capture mkdir "$tables\landshare"

* ANTT Tabela A displacement coefficients, R$/km, 6 axles (see antt_rates.csv)
global ccd_granel = 7.4408
global ccd_geral  = 7.4124
global ccd_frigo  = 8.7563
global payload_t  = 32
global speed_kmh  = 60

*----------------- 1. Value per ton, 2010 ------------------------------------*

use "$temp\landshare_micro.dta", clear
keep if year == 2010
collapse (sum) quantity value_prod, by(product)
* value_prod is in current mil reais; quantity in tons for unit_ton products
gen vpt = value_prod * 1000 / quantity
label var vpt "Value per ton, 2010 (R$)"
tempfile vpt
save `vpt'

*----------------- 2. Construct tau_g ----------------------------------------*

import delimited "$input\freight\product_class.csv", ///
    clear varnames(1) encoding(utf-8)
merge 1:1 product using `vpt', keep(1 3) nogen

gen ccd = cond(cargo_category == "granel", $ccd_granel, ///
          cond(cargo_category == "frigo",  $ccd_frigo,  $ccd_geral))
gen rate_ton_hr = ccd * $speed_kmh / $payload_t

gen tau_money    = rate_ton_hr / vpt if unit_ton == 1
gen tau_spoilage = 1 / (24 * shelf_life_days)
gen tau          = tau_money + tau_spoilage
gen ltau         = ln(tau)
label var tau  "Transport-cost sensitivity per hour (money + spoilage)"
label var ltau "Log tau_g"

tempfile tau
save `tau'

*----------------- 3. Test: gradients vs tau_g --------------------------------*

use "$temp\landshare_phi.dta", clear
merge 1:1 product using `tau', keep(3) nogen
keep if n_pos >= 50 & !missing(tau) & !missing(beta_iv)

di as result "=== products in tau test: " _N

* Prediction: beta_iv (share response to travel-time REDUCTION) increases
* in tau_g; the cross-sectional PPML gradient phi decreases in tau_g
reg beta_iv ltau
di as result "=== OLS beta_iv on ltau: " %8.5f _b[ltau] ///
    "  t = " %5.2f _b[ltau]/_se[ltau]
gen w = 1 / (se_iv^2)
reg beta_iv ltau [aweight = w]
di as result "=== WLS beta_iv on ltau: " %8.5f _b[ltau] ///
    "  t = " %5.2f _b[ltau]/_se[ltau]
spearman beta_iv ltau
di as result "=== spearman(beta_iv, ltau): " %6.3f r(rho) ///
    "  p = " %5.3f r(p)

* Components separately
spearman beta_iv tau_money
di as result "=== spearman(beta_iv, tau_money): " %6.3f r(rho) ///
    "  p = " %5.3f r(p)
spearman beta_iv tau_spoilage
di as result "=== spearman(beta_iv, tau_spoilage): " %6.3f r(rho) ///
    "  p = " %5.3f r(p)

* Tercile comparison
xtile tau3 = tau, nq(3)
tabstat beta_iv, by(tau3) stat(mean semean n)

export delimited product n_pos beta_iv se_iv phi_pois se_pois ///
    cargo_category shelf_life_days vpt tau_money tau_spoilage tau ///
    using "$tables\landshare\tau_test.csv", replace

twoway (scatter beta_iv ltau, mlabel(product) mlabsize(tiny)) ///
       (lfit beta_iv ltau), ///
    xtitle("Log transport-cost sensitivity (tau_g)") ///
    ytitle("IV land-share response to travel-time reduction") ///
    legend(off)
graph export "$tables\landshare\beta_tau.png", replace width(2000)
