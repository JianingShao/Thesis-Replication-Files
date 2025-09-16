
* program for panel combine
include "https://raw.githubusercontent.com/steveofconnell/PanelCombine/master/PanelCombine.do"


foreach X in gdp pop urbpop urbshare eap_urban eap_rural eapurbshare emp{
	* log change
	gen D`X'=log(`X'2010)-log(`X'1970)
	* baseline
	gen B`X'=log(`X'1970)
}

foreach X in soy cotton cattle{
	* log change
	gen D`X'=log(`X'2010+1)-log(`X'1970+1)
	* baseline
	gen B`X'=log(`X'1970+1)
}

* travel time
gen Dfm = log(fm1970/fm2010)
* instrument
gen pin_induced_reduction = log(fm1970) - log(fmpnv)
* region characteristics controls
gen logarea = log(area)

**********************************************************************
*** Table 1
**********************************************************************

eststo clear
foreach X in gdp pop urbpop urbshare soy cotton cattle{
	eststo: reg B`X' fm1970, cluster(uf)
}
esttab using "$output\table1.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N r2, labels("Observations" "$R^2$") fmt(0 3)) collabels(none) mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Soybean" "Cotton" "Cattle") keep(fm1970) varlabels(fm1970 "Log Travel Time to Port") label numbers title("Income, Population, Urbanization, Agricultural Production and Access to World Market") nonotes 

**********************************************************************
*** Table 2
**********************************************************************

eststo clear
foreach X in gdp pop urbpop urbshare{
	eststo: reghdfe D`X' Dfm B`X', cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table2_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("GDP" "Population" "Urban Population" "Urban Population Share", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Income and Population, 1970-2010") nonotes 

eststo clear
foreach X in gdp pop urbpop urbshare{
	eststo: reghdfe D`X' Dfm B`X', a(uf) cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', a(uf) cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table2_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("GDP" "Population" "Urban Population" "Urban Population Share", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Income and Population, 1970-2010") nonotes 

eststo clear
foreach X in gdp pop urbpop urbshare{
	eststo: reghdfe D`X' Dfm B`X' logarea lat lon, a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table2_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("GDP" "Population" "Urban Population" "Urban Population Share", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Income and Population, 1970-2010") nonotes 


cd "$output"
panelcombine, use(table2_A.tex table2_B.tex table2_C.tex)  columncount(8) paneltitles("(a) Baseline controlling only for the initial value of the outcome " "Panel (a) including state fixed effects" "Panel (b) including covariates for additional geographical traits") save(table2.tex) cleanup


**********************************************************************
*** Table 3
**********************************************************************
eststo clear
foreach X in emp soy cotton cattle{
	eststo: reghdfe D`X' Dfm B`X', cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table3_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Agricultural Employment" "Soybean" "Cotton" "Cattle", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Agricultural Production, 1970-2010") nonotes 

eststo clear
foreach X in emp soy cotton cattle{
	eststo: reghdfe D`X' Dfm B`X', a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table3_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Agricultural Employment" "Soybean" "Cotton" "Cattle", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Agricultural Production, 1970-2010") nonotes 

eststo clear
foreach X in emp soy cotton cattle{
	eststo: reghdfe D`X' Dfm B`X' logarea lat lon, a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table3_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Agricultural Employment" "Soybean" "Cotton" "Cattle", pattern(1 0 1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Agricultural Production, 1970-2010") nonotes 

cd "$output"
panelcombine, use(table3_A.tex table3_B.tex table3_C.tex)  columncount(8) paneltitles("(a) Baseline controlling only for the initial value of the outcome " "Panel (a) including state fixed effects" "Panel (b) including covariates for additional geographical traits") save(table3.tex) cleanup


**********************************************************************
*** Table 4: Extensive Margin
**********************************************************************

foreach X in soy cotton{
	gen `X'margin = (`X'1970==0 & (`X'1980 != 0 | `X'1985 != 0 | `X'1990 != 0 | `X'1995 != 0 | `X'2000 != 0 | `X'2005 != 0 | `X'2010 != 0))
}

eststo clear
foreach X in soy cotton{
	eststo: ivreghdfe `X'margin (Dfm = pin_induced_reduction) logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
	eststo: ivprobit `X'margin (Dfm = pin_induced_reduction) logarea lat lon i.uf, vce(cluster uf)
	margins, dydx(Dfm) predict(pr fix(Dfm))
}
esttab using "$output\table4.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Soybean" "Cotton", pattern(1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("LPM" "Probit" "LPM" "Probit") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Extensive Margin on Agricultural Production, 1970-2010") nonotes 

**********************************************************************
*** Table 5: Intensive Margin
**********************************************************************

foreach X in soy cotton{
	* log change
	gen DI`X'=log(`X'2010)-log(`X'1970)
	* baseline
	gen BI`X'=log(`X'1970)
}

eststo clear
foreach X in soy cotton{
	eststo: reghdfe DI`X' Dfm BI`X' logarea lat lon, a(uf) cluster(uf)
	eststo: ivreghdfe DI`X' (Dfm = pin_induced_reduction) BI`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table5.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup( "Soybean" "Cotton", pattern(1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Intensive Margin on Agricultural Production, 1970-2010") nonotes 

**********************************************************************
*** Table 6: Heterogeneity
**********************************************************************
egen mean_capdist = mean(dist_cap)
gen distcapdum=(dist_cap<mean_capdist)
eststo clear
foreach X in gdp pop urbpop urbshare emp soy cotton cattle{
	eststo: ivreghdfe D`X' (Dfm c.Dfm#i.distcapdum = pin_induced_reduction c.pin_induced_reduction#i.distcapdum) B`X' logarea lat lon, a(uf distcapdum) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\table6_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristcis") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Agricultural Employment" "Soybean" "Cotton" "Cattle") keep(Dfm 1.distcapdum#c.Dfm) varlabels(Dfm "$\Delta Log Travel Time$" 1.distcapdum#c.Dfm "$\Delta Log Travel Time \times Distance to Capital$") title("Interaction with Micro-Region Traits") nonotes 

gen cerrado = (region=="Centro-Oeste")
eststo clear
foreach X in gdp pop urbpop urbshare emp soy cotton cattle{
	eststo: ivreghdfe D`X' (Dfm c.Dfm#i.cerrado = pin_induced_reduction c.pin_induced_reduction#i.cerrado) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\table6_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristcis") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Agricultural Employment" "Soybean" "Cotton" "Cattle") keep(Dfm 1.cerrado#c.Dfm) varlabels(Dfm "$\Delta Log Travel Time$" 1.cerrado#c.Dfm "$\Delta Log Travel Time \times Center-West$") title("Interaction with Micro-Region Traits") nonotes 

egen mean_waterdist = mean(dist_water)
gen distwaterdum = (dist_water<mean_waterdist)
eststo clear
foreach X in gdp pop urbpop urbshare emp soy cotton cattle{
	eststo: ivreghdfe D`X' (Dfm c.Dfm#i.distwaterdum = pin_induced_reduction c.pin_induced_reduction#i.distwaterdum) B`X' logarea lat lon, a(uf distwaterdum) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\table6_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristics") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Agricultural Employment" "Soybean" "Cotton" "Cattle") keep(Dfm 1.distwaterdum#c.Dfm) varlabels(Dfm "$\Delta Log Travel Time$" 1.distwaterdum#c.Dfm "$\Delta Log Travel Time \times Distance to Waterway$") title("Interaction with Micro-Region Traits") nonotes 

cd "$output"
panelcombine, use(table6_A.tex table6_B.tex table6_C.tex)  columncount(8) paneltitles("(a) Baseline controlling only for the initial value of the outcome " "Panel (a) including state fixed effects" "Panel (b) including covariates for additional geographical traits") save(table6.tex) cleanup


**********************************************************************
*** Table 7: PPML
**********************************************************************
eststo clear
foreach X in soy cotton cattle{
	 eststo: ppmlhdfe `X'2010 Dfm B`X' logarea lat lon, a(uf) cluster(uf) offset(B`X')
	 quietly estadd local state "Yes", replace
	 quietly estadd local initial "Yes", replace
	 quietly estadd local resid "No", replace
	 gen ppmlsp = e(sample)
	 reghdfe Dfm pin_induced_reduction B`X' logarea lat lon if ppmlsp == 1 , a(uf) cluster(uf) res(resid)
	 eststo: ppmlhdfe `X'2010 Dfm logarea lat lon resid, a(uf) cluster(uf) offset(B`X')
	 quietly estadd local state "Yes", replace
	 quietly estadd local initial "Yes", replace
	 quietly estadd local resid "Yes", replace
	 drop resid ppmlsp
}
esttab using "$output\table7.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(state initial N resid, labels("State FE" "Initial level of outcome" "Observations" "First-stage residuals control") fmt(0 0 0 3)) collabels(none) label numbers mgroup("Soybean" "Cotton" "Cattle", pattern(1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("PPML" "IVPPML" "PPML" "IVPPML" "PPML" "IVPPML") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("PPML Regressions on Agricultural Production, 1970-2010") nonotes 



**********************************************************************
*** Table 8: Alternative Measures
**********************************************************************

eststo clear
foreach X in eap_rural eap_urban eapurbshare{
	eststo: reghdfe D`X' Dfm B`X', cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table8_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Rural Employment" "Urban Employment" "Urban Employment Share", pattern(1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Rual and Urban Employment, 1970-2010") nonotes 

eststo clear
foreach X in eap_rural eap_urban eapurbshare{
	eststo: reghdfe D`X' Dfm B`X', a(uf) cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X', a(uf) cluster(uf)
	quietly estadd local state "No", replace
	quietly estadd local initial "Yes", replace
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table8_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Rural Employment" "Urban Employment" "Urban Employment Share", pattern(1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Rual and Urban Employment, 1970-2010") nonotes 

eststo clear
foreach X in eap_rural eap_urban eapurbshare{
	eststo: reghdfe D`X' Dfm B`X' logarea lat lon, a(uf) cluster(uf)
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd scalar Fstat_KP = e(rkf)
}
esttab using "$output\table8_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N Fstat_KP, labels("Observations" "First-stage F stat") fmt(0 3)) collabels(none) label numbers mgroup("Rural Employment" "Urban Employment" "Urban Employment Share", pattern(1 0 1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) mlabel("OLS" "IV" "OLS" "IV" "OLS" "IV") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-Difference Regressions on Rual and Urban Employment, 1970-2010") nonotes 


cd "$output"
panelcombine, use(table8_A.tex table8_B.tex table8_C.tex)  columncount(8) paneltitles("(a) Baseline controlling only for the initial value of the outcome " "Panel (a) including state fixed effects" "Panel (b) including covariates for additional geographical traits") save(table8.tex) cleanup

**********************************************************************
*** Table 9: Alternative sample choices
**********************************************************************
eststo clear
foreach X in gdp pop urbpop urbshare emp soy cotton cattle{
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\table9_A.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristcis") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Agricultural Employment" "Soybean" "Cotton" "Cattle") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-difference estimates using alternative Sample Choices") nonotes 

preserve
drop if inlist(sigla, "AM", "AC", "RR", "AP", "PA")
eststo clear
foreach X in gdp pop urbpop urbshare emp soy cotton cattle{
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\table9_B.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristcis") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Agricultural Employment" "Soybean" "Cotton" "Cattle") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-difference estimates using alternative Sample Choices") nonotes 
restore

*** Meso-region ***
preserve
use "$input\meso.dta", clear

foreach X in gdp pop urbpop urbshare eap_urban eap_rural eapurbshare emp{
	* log change
	gen D`X'=log(`X'2010)-log(`X'1970)
	* baseline
	gen B`X'=log(`X'1970)
}

foreach X in soy cotton cattle{
	* log change
	gen D`X'=log(`X'2010+1)-log(`X'1970+1)
	* baseline
	gen B`X'=log(`X'1970+1)
}

* travel time
gen Dfm = log(fm1970/fm2010)
* instrument
gen pin_induced_reduction = log(fm1970) - log(fmpnv)
* region characteristics controls
gen logarea = log(area)

eststo clear
foreach X in gdp pop urbpop urbshare emp soy cotton cattle{
	eststo: ivreghdfe D`X' (Dfm = pin_induced_reduction) B`X' logarea lat lon, a(uf) cluster(uf)
	quietly estadd local state "Yes", replace
	quietly estadd local initial "Yes", replace
	quietly estadd local traits "Yes", replace
}
esttab using "$output\table9_C.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N state initial traits, labels("Observations" "State FE" "Initial level of outcome" "Geographical Characteristcis") fmt(0 0 0 0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Population Share" "Agricultural Employment" "Soybean" "Cotton" "Cattle") keep(Dfm) varlabels(Dfm "$\Delta Log Travel Time$") title("Long-difference estimates using alternative Sample Choices") nonotes 

cd "$output"
panelcombine, use(table9_A.tex table9_B.tex table9_C.tex)  columncount(8) paneltitles("(a) Micro-Regions" "(b) Micro-Regions dropping Amazon" "(c) Meso-Regions") save(table9.tex) cleanup
restore

