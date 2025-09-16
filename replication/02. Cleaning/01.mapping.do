import delimited "$input\amc_1970_2010.csv", clear
rename amc_1970_2 amc
save "$temp\amc_1970_2010.dta", replace
use "$temp\_Crosswalk_final_1970_2010.dta", clear
drop if amc==.
merge m:1 amc using "$temp\amc_1970_2010.dta"
keep final_name amc code2010 uf sigla regiã_o mesorregiã nome_meso microrregi nome_micro
rename mesorregiã meso
rename microrregi micro
rename regiã_o region

save "$temp\mapping.dta", replace
