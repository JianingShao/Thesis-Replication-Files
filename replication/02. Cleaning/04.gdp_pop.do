*** IV. GDP & Population ***

global year_gdp "1970 1975 1980 1985 1996 2000 2005 2010"
global year_pop "1950 1960 1970 1980 1991 2000 2010"


*** GDP ***
import excel "$input\gdp.xls", clear firstrow
rename Codigo code2010

merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3

* Micro
foreach var in $year_gdp {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen gdp`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\gdp_micro", replace

* Meso
foreach var in $year_gdp {
	bysort meso: egen gdp`var'_meso = sum(gdp`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\gdp_meso", replace

*** Population ***
import excel "$input\pop.xls", clear firstrow
rename Codigo code2010

merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3

* Micro
foreach var in $year_pop {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen pop`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\pop_micro", replace

* Meso
foreach var in $year_pop {
	bysort meso: egen pop`var'_meso = sum(pop`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\pop_meso", replace

*** Urban Population ***
import excel "$input\urbpop.xls", clear firstrow
rename Codigo code2010

merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge != 3

* Micro
foreach var in $year_pop {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen urbpop`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\urbpop_micro", replace

* Meso
foreach var in $year_pop {
	bysort meso: egen urbpop`var'_meso = sum(urbpop`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\urbpop_meso", replace