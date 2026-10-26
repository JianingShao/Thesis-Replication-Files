/*==============================================================================
PURPOSE:  Produce Tables 1-9. Called by master_analysis.do with micro.dta
          already in memory.

          T1  Descriptives: log outcomes on log travel time
          T2  Aggregate outcomes
          T3  Category land use
          T4  Pooled tau (croppanel.dta)
          T5  Extensive margin
          T6  Heterogeneity
          T7  PPML
          T8  Alternative measures
          T9  Alternative samples (meso.dta for Panel C)

          Panels A/B/C throughout: initial value of the outcome only / adding
          state fixed effects / adding geographic controls.

INPUT:    $input\micro.dta, $input\meso.dta, $input\croppanel.dta
OUTPUT:   $output\tab_descriptives.tex ... tab_altsamples.tex

NOTES:  1. Category columns (cropland, sens, ins, past, dom) and the named
           crops (soy, coffee) are built in 08.categories.do and carry the PAM
           1974 survey as year 1970; see 09.aggregation.do.
        2. Pasture is the cattle head count converted at one head per hectare,
           so it is a herd measure, not land.
        3. Crop outcomes use log(y+1) to keep micro-regions with no recorded
           area in the sample; the aggregate outcomes have no zeros and use
           plain logs.
==============================================================================*/

* program for panel combine
include "https://raw.githubusercontent.com/steveofconnell/PanelCombine/master/PanelCombine.do"

*------------------------- variable construction -----------------------------*

capture program drop mkvars
program define mkvars
    * Outcomes with no zeros: plain log
    foreach X in gdp pop urbpop urbshare eap_urban eap_rural eapurbshare emp {
        capture confirm variable `X'2010
        if _rc == 0 {
            quietly gen D`X' = log(`X'2010) - log(`X'1970)
            quietly gen B`X' = log(`X'1970)
        }
    }
    * Land, herd and crop outcomes: log(y+1) keeps the zeros
    foreach X in agland cropland sens ins past dom proc qsens qins soy coffee {
        capture confirm variable `X'2010
        if _rc == 0 {
            quietly gen D`X' = log(`X'2010 + 1) - log(`X'1970 + 1)
            quietly gen B`X' = log(`X'1970 + 1)
        }
    }
    * treatment, instrument, geographic controls
    quietly gen Dfm = log(fm1970/fm2010)
    quietly gen pin_induced_reduction = log(fm1970) - log(fmpnv)
    quietly gen logarea = log(area)
    quietly gen lfm = log(fm1970)

    label var Dfm "$\Delta$ Log Travel Time"
    label var pin_induced_reduction "PIN-Induced Reduction"
end

mkvars

* NB column headings are written out in full at each esttab call. Storing them
* in a global does not work: `global x "a" "b"' does not round-trip the quoted
* list, and esttab then silently drops the first group and emits a stray brace
* rather than erroring.

**********************************************************************
*** Table 1: Descriptives
**********************************************************************
* Log outcomes on log travel time, so the coefficients are elasticities and
* match the units of the treatment used from Section 5 onwards.

eststo clear
foreach X in gdp pop urbpop urbshare soy coffee past {
	eststo: reg B`X' lfm, cluster(uf)
}
esttab using "$output\tab_descriptives.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(4) star) se(fmt(4) par)) stats(N r2, labels("Observations" "\$R^2\$") fmt(0 3)) collabels(none) mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Soybean" "Coffee" "Cattle") keep(lfm) varlabels(lfm "Log Travel Time to Port") label numbers title("Income, Population, Urbanization, Agricultural Land Use and Access to World Market \label{tab:descriptives}") nonotes

**********************************************************************
*** Appendix Table A1: Product classification
**********************************************************************
* Every traded crop plus the exclusions, so the value-per-tonne gap and each
* exclusion can be checked. Sisal and castor print "--" for the export ratio:
* Brazil exports both heavily but their FAOSTAT export items do not match the
* production series, which is why they were added to the traded set by hand.

preserve
use "$input/products.dta", clear
keep if inlist(category_ex5,"exp_sensitive","exp_insensitive","exp_processed")

gen str24 name = ""
replace name = "Soybean"             if strpos(product,"Soja")>0
replace name = "Sisal"               if strpos(product,"Sisal")>0
replace name = "Castor"              if strpos(product,"Mamona")>0
replace name = "Walnut"              if strpos(product,"Noz")>0
replace name = "Coffee"              if strpos(product,"Caf")>0
replace name = "Black pepper"        if strpos(product,"Pimenta")>0
replace name = "Cocoa"               if strpos(product,"Cacau")>0
replace name = "Tobacco"             if strpos(product,"Fumo")>0
replace name = "Sugarcane"           if strpos(product,"Cana")>0
replace name = "Orange"              if strpos(product,"Laranja")>0
replace name = "Cotton (arboreal)"   if strpos(product,"arb")>0
replace name = "Cotton (herbaceous)" if strpos(product,"herb")>0
replace name = "Cashew"              if strpos(product,"caju")>0
replace name = "Peanut"              if strpos(product,"Amendoim")>0

* FAOSTAT items do not match for sisal and castor
gen byte nomatch = inlist(name,"Sisal","Castor")

gen byte ord = 1 if category_ex5=="exp_sensitive"
replace ord = 2 if category_ex5=="exp_insensitive"
replace ord = 3 if category_ex5=="exp_processed"
gsort ord vpt

file open ta1 using "$output/tab_classification.tex", write replace
file write ta1 "\begin{table}[htbp]\centering" _n
file write ta1 "\caption{Product Classification \label{tab:classification}}" _n
file write ta1 "\begin{tabular}{lccc}" _n
file write ta1 "\hline\hline" _n
file write ta1 " & Export & Value per & Micro-regions \\" _n
local bs = char(92)
file write ta1 "Crop & ratio & tonne (R`bs'$) & growing, 1974 (\%) \\" _n
file write ta1 "\hline" _n

local prev = 0
forvalues i = 1/`=_N' {
    if ord[`i'] != `prev' {
        if ord[`i'] == 1 file write ta1 "\multicolumn{4}{l}{\emph{Transport-cost-sensitive}} \\" _n
        if ord[`i'] == 2 file write ta1 "\addlinespace \multicolumn{4}{l}{\emph{Transport-cost-insensitive}} \\" _n
        if ord[`i'] == 3 file write ta1 "\addlinespace \multicolumn{4}{l}{\emph{Excluded}} \\" _n
        local prev = ord[`i']
    }
    local nm = name[`i']
    local ex = string(ex_g[`i'], "%4.2f")
    if nomatch[`i'] local ex "--"
    local vt = string(vpt[`i'], "%9.0fc")
    local pv = string(prev1974[`i'], "%4.1f")
    file write ta1 "\quad `nm' & `ex' & `vt' & `pv' \\" _n
}

file write ta1 "\hline\hline" _n
file write ta1 "\end{tabular}" _n
file write ta1 "\end{table}" _n
file close ta1
restore

**********************************************************************
*** Table 2: Proposition 1, aggregate outcomes
**********************************************************************

eststo clear
foreach X in gdp pop urbpop eapurbshare{
	eststo: reghdfe D`X' Dfm B`X', cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace

	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_aggregate_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("GDP" "Population" "Urban Population" "Urban Employment Share", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Income and Population, 1970-2010 \label{tab:aggregate}") nonotes

eststo clear
foreach X in gdp pop urbpop eapurbshare{
	eststo: reghdfe D`X' Dfm B`X', a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace

	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_aggregate_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("GDP" "Population" "Urban Population" "Urban Employment Share", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Income and Population, 1970-2010 \label{tab:aggregate}") nonotes

eststo clear
foreach X in gdp pop urbpop eapurbshare{
	eststo: reghdfe D`X' Dfm B`X' logarea lat lon, a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_aggregate_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("GDP" "Population" "Urban Population" "Urban Employment Share", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Income and Population, 1970-2010 \label{tab:aggregate}") nonotes

cd "$output"
panelcombine, use(tab_aggregate_A.tex tab_aggregate_B.tex tab_aggregate_C.tex)  columncount(8) paneltitles("Baseline controlling only for the initial value of the outcome" "Panel (A) including state fixed effects" "Panel (B) including covariates for additional geographical traits") save(tab_aggregate.tex) cleanup

**********************************************************************
*** Table 3: Proposition 2a, category land use
**********************************************************************
* Column 1 is total cropland, pasture excluded.

eststo clear
foreach X in cropland sens ins past{
	eststo: reghdfe D`X' Dfm B`X', cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_landuse_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Total Cropland" "Sensitive" "Insensitive" "Pasture", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Agricultural Land Use, 1974-2010 \label{tab:landuse}") nonotes

eststo clear
foreach X in cropland sens ins past{
	eststo: reghdfe D`X' Dfm B`X', a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_landuse_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Total Cropland" "Sensitive" "Insensitive" "Pasture", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Agricultural Land Use, 1974-2010 \label{tab:landuse}") nonotes

eststo clear
foreach X in cropland sens ins past{
	eststo: reghdfe D`X' Dfm B`X' logarea lat lon, a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_landuse_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Total Cropland" "Sensitive" "Insensitive" "Pasture", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Agricultural Land Use, 1974-2010 \label{tab:landuse}") nonotes

cd "$output"
panelcombine, use(tab_landuse_A.tex tab_landuse_B.tex tab_landuse_C.tex)  columncount(8) paneltitles("Baseline controlling only for the initial value of the outcome" "Panel (A) including state fixed effects" "Panel (B) including covariates for additional geographical traits") save(tab_landuse.tex) cleanup

**********************************************************************
*** Table 4: Proposition 2b, pooled tau
**********************************************************************
* Crop x micro-region. Product fixed effects absorb the good-specific price
* and the tau main effect; micro-region fixed effects absorb the CES
* denominator and the travel-time main effect. Only the interaction is
* identified, and it is instrumented by tau x PIN. Clustered on micro-region.

preserve
use "$input\croppanel.dta", clear

quietly gen double tau_dtt = .
quietly gen double tau_pin = .
label var tau_dtt "$\tau_g \times \Delta$ Log Travel Time"

eststo clear
foreach Y in dlnarea dshare {
	foreach T in sens vpt {
		quietly replace tau_dtt = `T'_dtt
		quietly replace tau_pin = `T'_pin
		eststo: ivreghdfe `Y' (tau_dtt = tau_pin), absorb(prodid micro) cluster(micro)
		quietly estadd scalar Fstat_KP = e(rkf)
		quietly estadd local prodfe "Yes", replace
		quietly estadd local microfe "Yes", replace
	}
}
esttab using "$output\tab_pooledtau.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(4) star) se(fmt(4) par)) stats(prodfe microfe N Fstat_KP, labels("Product FE" "Micro-region FE" "Observations" "First-stage F stat") fmt(0 0 0 3)) collabels(none) label numbers mgroup("$\Delta$ Log Area" "$\Delta$ Land Share", pattern(1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("Binary $\tau$" "Log Value/Ton" "Binary $\tau$" "Log Value/Ton") keep(tau_dtt) varlabels(tau_dtt "$\tau_g \times \Delta Log Travel Time$") substitute(\_ _) title("Pooled Transport-Sensitivity Interaction, Traded Crops, 1974-2010 \label{tab:pooledtau}") nonotes
restore

**********************************************************************
*** Table 5: Extensive Margin
**********************************************************************
* Entry: no recorded area in 1974 and positive area in 2010. Pasture and
* domestic crops are present in essentially every micro-region in 1974, so
* only the two traded categories appear.

foreach X in sens ins{
	gen `X'margin = (`X'1970 == 0 & `X'2010 > 0)
}

eststo clear
foreach X in sens ins{
	eststo: ivreghdfe `X'margin (Dfm = pin_induced_reduction) logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
	quietly estadd local model "LPM", replace

	quietly ivprobit `X'margin (Dfm = pin_induced_reduction) logarea lat lon i.uf, vce(cluster uf)
	quietly margins, dydx(Dfm) predict(pr fix(Dfm)) post
	eststo
	quietly estadd local model "Probit ME", replace
}
esttab using "$output\tab_extensive.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Sensitive" "Insensitive", pattern(1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("LPM" "Probit" "LPM" "Probit") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Extensive Margin of Agricultural Land Use, 1974-2010 \label{tab:extensive}") nonotes

**********************************************************************
*** Table 6: Heterogeneity
**********************************************************************
* Aggregate outcomes, matched to Table 2.

egen mean_waterdist = mean(dist_water)
gen distwaterdum = (dist_water < mean_waterdist)
eststo clear
foreach X in gdp pop urbpop eapurbshare{
	eststo: ivreghdfe D`X' (Dfm c.Dfm#i.distwaterdum = pin_induced_reduction c.pin_induced_reduction#i.distwaterdum) B`X' logarea lat lon, a(uf distwaterdum) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\tab_heterogeneity_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristics") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Employment Share") keep(Dfm 1.distwaterdum#c.Dfm) varlabels(Dfm "$\Delta Log Travel Time$" 1.distwaterdum#c.Dfm "$\Delta Log Travel Time \times Distance to Waterway$") title("Interaction with Micro-Region Traits \label{tab:heterogeneity}") nonotes

gen cerrado = (region == "Centro-Oeste")
eststo clear
foreach X in gdp pop urbpop eapurbshare{
	eststo: ivreghdfe D`X' (Dfm c.Dfm#i.cerrado = pin_induced_reduction c.pin_induced_reduction#i.cerrado) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\tab_heterogeneity_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristics") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Employment Share") keep(Dfm 1.cerrado#c.Dfm) varlabels(Dfm "$\Delta Log Travel Time$" 1.cerrado#c.Dfm "$\Delta Log Travel Time \times Center-West$") title("Interaction with Micro-Region Traits \label{tab:heterogeneity}") nonotes

egen mean_capdist = mean(dist_cap)
gen distcapdum = (dist_cap < mean_capdist)
eststo clear
foreach X in gdp pop urbpop eapurbshare{
	eststo: ivreghdfe D`X' (Dfm c.Dfm#i.distcapdum = pin_induced_reduction c.pin_induced_reduction#i.distcapdum) B`X' logarea lat lon, a(uf distcapdum) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\tab_heterogeneity_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristics") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Employment Share") keep(Dfm 1.distcapdum#c.Dfm) varlabels(Dfm "$\Delta Log Travel Time$" 1.distcapdum#c.Dfm "$\Delta Log Travel Time \times Distance to Capital$") title("Interaction with Micro-Region Traits \label{tab:heterogeneity}") nonotes

cd "$output"
panelcombine, use(tab_heterogeneity_A.tex tab_heterogeneity_B.tex tab_heterogeneity_C.tex)  columncount(4) paneltitles("Distance to Waterway" "Center-West Region" "Distance to State Capital") save(tab_heterogeneity.tex) cleanup

**********************************************************************
*** Table 7: PPML
**********************************************************************
* Outcomes matched to Table 3. Column 2 of each pair is the reduced form,
* PPML on the PIN-predicted reduction.

eststo clear
foreach X in cropland sens ins past{
	eststo: ppmlhdfe `X'2010 Dfm B`X' logarea lat lon, a(uf) cluster(uf) offset(B`X')
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace

	eststo: ppmlhdfe `X'2010 pin_induced_reduction B`X' logarea lat lon, a(uf) cluster(uf) offset(B`X')
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
}
esttab using "$output\tab_ppml.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(state initial N, labels("State FE" "Initial level of outcome" "Observations") fmt(0 0 0)) collabels(none) label numbers mgroup("Total Cropland" "Sensitive" "Insensitive" "Pasture", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("PPML" "Reduced Form" "PPML" "Reduced Form" "PPML" "Reduced Form" "PPML" "Reduced Form") keep(Dfm pin_induced_reduction) varlabels(Dfm "$\Delta Log Travel Time$" pin_induced_reduction "PIN-Induced Reduction") title("PPML Regressions on Agricultural Land Use, 1974-2010 \label{tab:ppml}") nonotes

**********************************************************************
*** Table 8: Alternative Measures
**********************************************************************
* Employment counts in place of the urbanization shares, and the traded
* categories measured in output rather than harvested area. IBGE reports no
* output quantity for pasture, so that column stays on the head count.

eststo clear
foreach X in eap_rural eap_urban qsens qins past{
	eststo: reghdfe D`X' Dfm B`X', cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_altmeasures_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Rural Employment" "Urban Employment" "Sensitive" "Insensitive" "Pasture", pattern(1 0 1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Alternative Measures of Employment and Agricultural Output \label{tab:altmeasures}") nonotes

eststo clear
foreach X in eap_rural eap_urban qsens qins past{
	eststo: reghdfe D`X' Dfm B`X', a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_altmeasures_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Rural Employment" "Urban Employment" "Sensitive" "Insensitive" "Pasture", pattern(1 0 1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Alternative Measures of Employment and Agricultural Output \label{tab:altmeasures}") nonotes

eststo clear
foreach X in eap_rural eap_urban qsens qins past{
	eststo: reghdfe D`X' Dfm B`X' logarea lat lon, a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\tab_altmeasures_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Rural Employment" "Urban Employment" "Sensitive" "Insensitive" "Pasture", pattern(1 0 1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Alternative Measures of Employment and Agricultural Output \label{tab:altmeasures}") nonotes

cd "$output"
panelcombine, use(tab_altmeasures_A.tex tab_altmeasures_B.tex tab_altmeasures_C.tex)  columncount(10) paneltitles("Baseline controlling only for the initial value of the outcome" "Panel (A) including state fixed effects" "Panel (B) including covariates for additional geographical traits") save(tab_altmeasures.tex) cleanup

**********************************************************************
*** Table 9: Alternative sample choices
**********************************************************************
* Outcomes matched to Tables 2 and 3, fully controlled specification.

eststo clear
foreach X in gdp pop urbpop eapurbshare cropland sens ins past{
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\tab_altsamples_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristics") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Employment Share" "Total Cropland" "Sensitive" "Insensitive" "Pasture") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-difference estimates using alternative Sample Choices \label{tab:altsamples}") nonotes

preserve
drop if inlist(sigla, "AM", "AC", "RR", "AP", "PA")
eststo clear
foreach X in gdp pop urbpop eapurbshare cropland sens ins past{
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\tab_altsamples_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristics") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Employment Share" "Total Cropland" "Sensitive" "Insensitive" "Pasture") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-difference estimates using alternative Sample Choices \label{tab:altsamples}") nonotes
restore

*** Meso-region ***
preserve
use "$input\meso.dta", clear
mkvars

eststo clear
foreach X in gdp pop urbpop eapurbshare cropland sens ins past{
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\tab_altsamples_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristics") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Employment Share" "Total Cropland" "Sensitive" "Insensitive" "Pasture") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-difference estimates using alternative Sample Choices \label{tab:altsamples}") nonotes
restore

cd "$output"
panelcombine, use(tab_altsamples_A.tex tab_altsamples_B.tex tab_altsamples_C.tex)  columncount(8) paneltitles("Micro-regions" "Micro-regions excluding the Amazon" "Meso-regions") save(tab_altsamples.tex) cleanup
