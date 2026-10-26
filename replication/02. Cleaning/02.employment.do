*** III. Employment ***

global year_emp "1970 1975 1980 1985 1995 2006"
global year_eap "1970 1980 1991 2000 2010"

*** Personnel employed in agricultural establishments ***
import excel "$input\agroemp.xls", clear firstrow
rename Codigo code2010

merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3

* Micro
foreach var in $year_emp {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen emp`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\agroemp_micro", replace

* Meso
foreach var in $year_emp {
	bysort meso: egen emp`var'_meso = sum(emp`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\agroemp_meso", replace


*** Economically Active Population - rural ***
import excel "$input\eap_rural.xls", clear firstrow
rename Codigo code2010

merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3

* Micro
foreach var in $year_eap {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen eap_rural`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\eap_rural_micro", replace

* Meso
foreach var in $year_eap {
	bysort meso: egen eap_rural`var'_meso = sum(eap_rural`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\eap_rural_meso", replace

*** Economically Active Population - urban ***
import excel "$input\eap_urban.xls", clear firstrow
rename Codigo code2010

merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3

* Micro
foreach var in $year_eap {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen eap_urban`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\eap_urban_micro", replace

* Meso
foreach var in $year_eap {
	bysort meso: egen eap_urban`var'_meso = sum(eap_urban`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\eap_urban_meso", replace