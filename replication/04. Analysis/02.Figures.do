
foreach X in pop urbpop urbshare{
	foreach year in 1950 1960 1970 1980 1990 2000 2010{
		gen log`X'`year'=log(`X'`year')
	}
}

foreach X in gdp{
	foreach year in 1970 1975 1980 1985 1995 2000 2005 2010{
		gen log`X'`year'=log(`X'`year')
	}
}

foreach X in soy cotton cattle{
	foreach year in 1970 1980 1985 1990 1995 2000 2005 2010{
		gen log`X'`year'=log(`X'`year'+1)
	}
}

foreach year in 1960 1970 1980 1990 2000 2010{
	gen logfm`year'=log(fm`year')
}


**********************************************************************
*** Figure 3/4: Event Study
**********************************************************************
eststo clear
foreach X in gdp pop urbpop urbshare{
	preserve
	keep micro log`X'* pin_induced_reduction
	reshape long log`X', i(micro) j(year)
	event_study_plot, depvar(log`X') inst(pin_induced_reduction) baseyear(1970)
	* make the event study plot
	twoway (sc beta year, mcolor(navy) lwidth(medthick) lcolor(navy) connect(direct)) ///
		  (rcap lb ub year, lcolor(navy)), ///
		  xtitle("Year") ytitle("Coefficients") legend(off) ///
		  xline(1974 1988, lcolor(black) lpattern("dash")) scheme(plotplain)
	graph export "$output\\`X'.png", replace
	restore
}
esttab using "$output\appendix\table1.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N, labels("Observations") fmt(0)) collabels(none) label numbers mlabel("GDP" "Population" "Urban Population" "Urban Population Share") keep(*.year#c.pin_induced_reduction) order(1950.year#c.pin_induced_reduction 1960.year#c.pin_induced_reduction) title("Event Study on Income and Population, 1970-2010") nonotes
eststo clear

foreach X in soy cotton cattle{
	preserve
	keep micro log`X'* pin_induced_reduction
	reshape long log`X', i(micro) j(year)
	event_study_plot, depvar(log`X') inst(pin_induced_reduction) baseyear(1970)
	* make the event study plot
	twoway (sc beta year, mcolor(navy) lwidth(medthick) lcolor(navy) connect(direct)) ///
		  (rcap lb ub year, lcolor(navy)), ///
		  xtitle("Year") ytitle("Coefficients") legend(off) ///
		  xline(1974 1988, lcolor(black) lpattern("dash")) scheme(plotplain) ///
		  ysc(range(-1 6))
	graph export "$output\\`X'.png", replace
	restore
}
esttab using "$output\appendix\table2.tex", replace star(* 0.1 ** 0.05 *** 0.01) cell(b(fmt(3) star) se(fmt(3) par)) stats(N, labels("Observations") fmt(0)) collabels(none) label numbers mlabel("Soybean" "Cotton" "Cattle") keep(*.year#c.pin_induced_reduction)  title("Event Study on Agricultural Production, 1970-2010") nonotes
eststo clear

**********************************************************************
*** Figure 5: Event Study of IV first stage 
**********************************************************************
*** TWFE ***
preserve
keep micro logfm* pin_induced_reduction
reshape long logfm, i(micro) j(year)
event_study_plot, depvar(logfm) inst(pin_induced_reduction) baseyear(1970)
twoway (sc beta year, mcolor(navy) lwidth(medthick) lcolor(navy) connect(direct)) ///
	   (rcap lb ub year, lcolor(navy)), ///
	    xtitle("Year") ytitle("Coefficients") legend(off) ///
		xline(1974, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\road_twfe.png", replace
restore

*** Imputation ***
preserve
keep micro logfm* pin_induced_reduction
reshape long logfm,  i(micro) j(year)
event_study_plot_imputation fm 3 2 10 3
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = t - 3 if t>=3
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\road_imputation.png", replace
restore

*** CS ***
preserve
keep micro logfm* pin_induced_reduction
reshape long logfm,  i(micro) j(year)
event_study_plot_csdid fm 3 2 3
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = t - 3 if t>=3
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\road_csdid.png", replace
restore



**********************************************************************
*** Appendix Figure 3: Event Study of urban population
**********************************************************************
*** Imputation ***
preserve
keep micro logurbpop* pin_induced_reduction
reshape long logurbpop,  i(micro) j(year)
event_study_plot_imputation urbpop 3 3 10 4
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = -3 if t == 3
replace t = t - 4 if t>=4
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-3 "1950" -2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\appendix\urbpop_imputation.png", replace
restore

*** CS ***
preserve
keep micro logurbpop* pin_induced_reduction
reshape long logurbpop,  i(micro) j(year)
event_study_plot_csdid urbpop 3 3 4
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = -3 if t == 3
replace t = t - 4 if t>=4
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-3 "1950" -2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\appendix\urbpop_csdid.png", replace
restore

**********************************************************************
*** Appendix Figure 4: Event Study of urban population share
**********************************************************************
*** Imputation ***
preserve
keep micro logurbshare* pin_induced_reduction
reshape long logurbshare,  i(micro) j(year)
event_study_plot_imputation urbshare 3 3 10 4
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = -3 if t == 3
replace t = t - 4 if t>=4
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-3 "1950" -2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\appendix\urbshare_imputation.png", replace
restore

*** CS ***
preserve
keep micro logurbshare* pin_induced_reduction
reshape long logurbshare,  i(micro) j(year)
event_study_plot_csdid urbshare 3 3 4
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = -3 if t == 3
replace t = t - 4 if t>=4
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-3 "1950" -2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\appendix\urbshare_csdid.png", replace
restore

**********************************************************************
*** Appendix Figure 4: Event Study of urban population share
**********************************************************************
*** Imputation ***
preserve
keep micro logpop* pin_induced_reduction
reshape long logpop,  i(micro) j(year)
event_study_plot_imputation pop 3 3 10 4
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = -3 if t == 3
replace t = t - 4 if t>=4
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-3 "1950" -2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\appendix\pop_imputation.png", replace
restore

*** CS ***
preserve
keep micro logpop* pin_induced_reduction
reshape long logpop,  i(micro) j(year)
event_study_plot_csdid pop 3 3 4
replace t = -1 if t == 1
replace t = -2 if t == 2
replace t = -3 if t == 3
replace t = t - 4 if t>=4
sort t
twoway (sc didcoef t, mcolor(navy) lcolor(navy) lwidth(medthick) connect(direct)) ///
(rcap didci_low didci_high t, lcolor(navy)), ///
 xlabel(-3 "1950" -2 "1960" -1 "1970" 0 "1980" 1 "1990" 2 "2000" 3 "2010") xtitle("Year") ytitle("Coefficients") legend(off) ///
xline(-0.6, lcolor(black) lpattern("dash")) scheme(plotplain)
graph export "$output\appendix\pop_csdid.png", replace
restore


**********************************************************************
*** Appendix Figure 5-7: Imputation Treatment Intensity
**********************************************************************
foreach v in pop urbpop urbshare{
	preserve
	keep micro log`v'* pin_induced_reduction
	reshape long log`v',  i(micro) j(year)
	sum pin_induced_reduction, detail
	gen discrete_instrument = (pin_induced_reduction >= `r(p50)')
	gen start = 1970
	gen treatment_date = discrete_instrument*start
	replace treatment_date = . if discrete_instrument == 0
	did_imputation log`v' micro year treatment_date, delta(10) hor(0/4) pretrend(2) autosample cluster(micro) saveestimates(tau)
	drop if tau==.
	global year 1970 1980 1990 2000 2010
	foreach y in $year{
		twoway (scatter tau pin_induced_reduction if year == `y') ///
			   (lfit tau pin_induced_reduction if year == `y'), ///
			   xtitle("Treatment Intensity") ///
			   ytitle("Coefficients") ///
			   legend(off) ///
			   scheme(plotplain) ///
			   ysc(range(-1.5 1.5))
		graph export "$output\appendix\\`v'_treatment_intensity_`y'.png", replace
	}
restore
}
