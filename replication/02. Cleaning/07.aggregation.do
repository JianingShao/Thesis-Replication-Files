*** Micro ***
use "$temp\traveltime_micro", clear
global data_micro "gdp pop urbpop eap_urban eap_rural agroemp soy cotton cattle geo waterway dis_capital"
foreach d in $data_micro{
	merge 1:1 micro using "$temp/`d'_micro.dta"
	drop _merge
}
* drop oversea island
drop if micro==26019
* suitability
drop if arrival_time_1970_amc_micro==.

*clean
ds *_micro
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "_micro", "", .)
    rename `var' `newname'
}
ds *73
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "73", "70", .)
    rename `var' `newname'
}
ds *74
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "74", "70", .)
    rename `var' `newname'
}
ds *91
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "91", "90", .)
    rename `var' `newname'
}
ds arrival_time_*_amc
foreach var in `r(varlist)' {
    local tempname = subinstr("`var'", "arrival_time_", "", .)
    local year = subinstr("`tempname'", "_amc", "", .)
    local newname = "fm" + "`year'"
    rename `var' `newname'
}
rename emp2006 emp2010
rename gdp1996 gdp1995
foreach year in 1950 1960 1970 1980 1990 2000 2010{
	gen urbshare`year' = urbpop`year'/pop`year'
}
foreach year in 1970 1980 1990 2000 2010{
	gen eapurbshare`year' = eap_urban`year'/(eap_urban`year'+eap_rural`year')
}

save "$output\micro.dta", replace


*** Meso ***
use "$temp\traveltime_meso", clear
global data_meso "gdp pop urbpop eap_urban eap_rural agroemp soy cotton cattle geo"
foreach d in $data_meso{
	merge 1:1 meso using "$temp/`d'_meso.dta"
	drop _merge
}

*clean
ds *_meso
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "_meso", "", .)
    rename `var' `newname'
}
ds *73
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "73", "70", .)
    rename `var' `newname'
}
ds *74
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "74", "70", .)
    rename `var' `newname'
}
ds *91
foreach var of varlist `r(varlist)' {
    local newname = subinstr("`var'", "91", "90", .)
    rename `var' `newname'
}
ds arrival_time_*_amc
foreach var in `r(varlist)' {
    local tempname = subinstr("`var'", "arrival_time_", "", .)
    local year = subinstr("`tempname'", "_amc", "", .)
    local newname = "fm" + "`year'"
    rename `var' `newname'
}
rename emp2006 emp2010
rename gdp1996 gdp1995
foreach year in 1950 1960 1970 1980 1990 2000 2010{
	gen urbshare`year' = urbpop`year'/pop`year'
}
foreach year in 1970 1980 1990 2000 2010{
	gen eapurbshare`year' = eap_urban`year'/(eap_urban`year'+eap_rural`year')
}

save "$output\meso.dta", replace