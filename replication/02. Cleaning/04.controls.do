*** V. Geographical Characteristics ***

* Micro
import delimited "$input\characteristics_micro.csv", clear
rename microrregi micro
drop shape*
save "$temp\geo_micro", replace

import delimited "$input\waterway.csv", clear
rename microrregi micro
keep micro dist_water
save "$temp\waterway_micro", replace

import delimited "$input\dis_capital.csv", clear
rename microrregi micro
rename near_dist dist_cap
keep micro dist_cap
save "$temp\dis_capital_micro", replace



* Meso
import delimited "$input\characteristics_meso.csv", clear
rename mesorregiã meso
drop shape*
save "$temp\geo_meso", replace
