*** II. Commondity Production ***

*** Soybean ***
import excel "$input\soy.xls", clear firstrow
rename Codigo code2010

merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3

global year_soy "1973 1980 1985 1990 1995 2000 2005 2010"

* Micro
foreach var in $year_soy {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregare to Micro level
	bysort micro: egen soy`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\soy_micro", replace

* Meso
foreach var in $year_soy {
	bysort meso: egen soy`var'_meso = sum(soy`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\soy_meso", replace


*** Cattle ***
import excel "$input\cattle.xls", clear firstrow
rename Codigo code2010
merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3
global year_cattle "1974 1980 1985 1990 1995 2000 2005 2010"

* Micro
foreach var in $year_cattle {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen cattle`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\cattle_micro", replace

* Meso
foreach var in $year_cattle {
	bysort meso: egen cattle`var'_meso = sum(cattle`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\cattle_meso", replace


*** Cotton ***
import excel "$input\cotton.xls", clear firstrow
rename Codigo code2010
merge m:1 code2010 using "$temp\mapping.dta"
drop if _merge!=3
global year_cotton "1973 1980 1985 1990 1995 2000 2005 2010"

* Micro
foreach var in $year_cotton {
	* Fill missing values with 0
    replace Year`var' = 0 if missing(Year`var')
	* Aggregate to Micro level
	bysort micro: egen cotton`var'_micro = sum(Year`var')
}
keep uf sigla region meso *micro 
duplicates drop
save "$temp\cotton_micro", replace

* Meso
foreach var in $year_cotton {
	bysort meso: egen cotton`var'_meso = sum(cotton`var'_micro)
}
keep uf sigla region *meso 
duplicates drop
save "$temp\cotton_meso", replace