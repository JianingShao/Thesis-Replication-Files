*** Event Study ***
capture program drop event_study_plot
program define event_study_plot

	syntax [varlist], depvar(string) inst(string) baseyear(real)
	
	* Run the event study regression
	eststo: reghdfe `depvar' c.`inst'##ib`baseyear'.year, a(micro) vce(cluster micro)

	* save beta and se
	matrix beta = e(b)
	mata st_matrix("se",sqrt(diagonal(st_matrix("e(V)")))') 
	
	* convert to variables
	svmat beta
	svmat se

	* reshape beta and s.e. to plot
	keep beta* se*
	keep if _n==1
	gen i = 1
	reshape long beta se, i(i) j(num)

	* attach label 
	local names: colfullnames beta, quoted
	sum num
	gen varname = ""
	forvalues i = 1/`r(max)' {
		local betaname : word `i' of `names'
		di in red "`i', `betaname'"
		replace varname = "`betaname'" if num == `i'
		}

	* now we just want to plot the treatment effects of the PIN-induced reduction in travel time (including omitted base value)
	keep if regexm(varname, "c.`inst'") | regexm(varname, "co.`inst'")
	gen year = substr(varname,1,4)
	destring year, replace

	* make the 95% c.i.
	gen lb = beta-1.96*se
	gen ub = beta+1.96*se

end




*** Event Study, state x year fixed effects ***
* Identical to event_study_plot except that state x year fixed effects are
* absorbed alongside the micro-region effects. Requires uf to be present in
* the estimation sample.
capture program drop event_study_plot_sy
program define event_study_plot_sy

	syntax [varlist], depvar(string) inst(string) baseyear(real)

	* Run the event study regression
	eststo: reghdfe `depvar' c.`inst'##ib`baseyear'.year, a(micro uf#year) vce(cluster micro)

	* save beta and se
	matrix beta = e(b)
	mata st_matrix("se",sqrt(diagonal(st_matrix("e(V)")))')

	* convert to variables
	svmat beta
	svmat se

	* reshape beta and s.e. to plot
	keep beta* se*
	keep if _n==1
	gen i = 1
	reshape long beta se, i(i) j(num)

	* attach label
	local names: colfullnames beta, quoted
	sum num
	gen varname = ""
	forvalues i = 1/`r(max)' {
		local betaname : word `i' of `names'
		replace varname = "`betaname'" if num == `i'
		}

	* keep the treatment effects of the instrument (including the omitted base)
	keep if regexm(varname, "c.`inst'") | regexm(varname, "co.`inst'")
	gen year = substr(varname,1,4)
	destring year, replace

	* make the 95% c.i.
	gen lb = beta-1.96*se
	gen ub = beta+1.96*se

end


*** Imputator (Borusyak et al. 2024) ***
cap program drop event_study_plot_imputation

program event_study_plot_imputation

	*microregions are treated if they have above median reduction in travel time on the PIN network
	sum pin_induced_reduction, detail
	gen discrete_instrument = (pin_induced_reduction >= `r(p50)')

	gen start = 1980
	gen treatment_date = discrete_instrument*start
	replace treatment_date = . if discrete_instrument == 0

	xtset micro year

	did_imputation log`1' micro year treatment_date, delta(`4') hor(0/`2') pretrend(`3') autosample cluster(micro)

	statsby _b _se , clear: did_imputation log`1' micro year treatment_date, delta(`4') hor(0/`2') pretrend(`3') autosample cluster(micro)

	display in red "did_imputation log`1' micro year treatment_date, delta(`4') hor(0/`2') pretrend(`3') autosample cluster(micro)"

	* format and reshape for plotting, calculate confidence intervals

	gen x = 1

	forvalues i=0/`2'{
		local j = `i' + `5'
		gen didci_low`j' = _b_tau`i' - 1.96*_se_tau`i'
		gen didci_high`j' = _b_tau`i' + 1.96*_se_tau`i'
		rename _b_tau`i' didcoef`j'
	}

	forvalues i=1/`3'{
		gen didci_low`i' = _b_pre`i' - 1.96*_se_pre`i'
		gen didci_high`i' = _b_pre`i' + 1.96*_se_pre`i'
		rename _b_pre`i' didcoef`i'
			}

	reshape long didcoef didci_low didci_high, i(x) j(t)
	
end


*** CS (Callaway and Sant'Anna, 2021) ***
cap program drop event_study_plot_csdid

program event_study_plot_csdid

	*microregions are treated if they have above median reduction in travel time on the PIN network
	sum pin_induced_reduction, detail
	gen discrete_instrument = (pin_induced_reduction >= `r(p50)')

	gen start = 1980
	gen treatment_date = discrete_instrument*start

	csdid log`1', time(year) ivar(micro) gvar(treatment_date) agg(event) long2

	statsby _b _se , clear: csdid log`1', time(year) ivar(micro) gvar(treatment_date) agg(event) long2
	gen _b_Tm10 = 0
	gen _se_Tm10 = 0

	display in red "csdid log`1', time(year) ivar(micro) gvar(treatment_date) agg(event)"

	* format and reshape for plotting, calculate confidence intervals

	gen x = 1

	forvalues i=0/`2'{
		local j = `i' + `4'
		gen didci_low`j' = _b_Tp`i' - 1.96*_se_Tp`i'
		gen didci_high`j' = _b_Tp`i' + 1.96*_se_Tp`i'
		rename _b_Tp`i' didcoef`j'
	}

	forvalues i=1/`3'{
		gen didci_low`i' = _b_Tm`i' - 1.96*_se_Tm`i'
		gen didci_high`i' = _b_Tm`i' + 1.96*_se_Tm`i'
		rename _b_Tm`i' didcoef`i'
	}

	reshape long didcoef didci_low didci_high, i(x) j(t)
	
end


