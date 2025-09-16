*** VII. Travel Time ***

*** Micro ***
import delimited "$input\fmm_amc_micro.csv", clear
rename amc_micromicrorregi micro
drop v1
destring arrival*, force replace
* assign travel time of the mean of the closest 2 micro to NA
replace arrival_time_pnv_amc_micro = 90 if micro==27010
replace arrival_time_pnv_amc_micro = 40 if micro==41038
* adjust misreported value due to algorithm limitation 
* micro 15007
expand 2 if micro==15008, gen(dupindicator)
drop if micro==15007
replace micro=15007 if dupindicator==1
drop dupindicator
* micro 21002
replace arrival_time_pnv_amc_micro = 6.6666667 if micro==21002
* micro 32009
global fmm 1960 1970 1980 1990 2000 2010 pnv
foreach v in $fmm{
    replace arrival_time_`v'_amc_micro = 3.333 if micro==32009
}
* micro 29019
replace arrival_time_pnv_amc_micro = 10.323831 if micro==29019
* micro 29021
replace arrival_time_pnv_amc_micro = 5 if micro==29021
* micro 35059
replace arrival_time_pnv_amc_micro = 10.306825 if micro==35059
* micro 35060
replace arrival_time_pnv_amc_micro = 10 if micro==35060
* micro 35061
replace arrival_time_pnv_amc_micro = 5.4602373 if micro==35061
* micro
expand 2 if micro==32009, gen(dupindicator)
drop if micro==35063
replace micro=35063 if dupindicator==1
drop dupindicator

sort micro

replace arrival_time_1980_amc_micro = arrival_time_1970_amc_micro if arrival_time_1980_amc_micro > arrival_time_1970_amc_micro
replace arrival_time_1990_amc_micro = arrival_time_1980_amc_micro if arrival_time_1990_amc_micro > arrival_time_1980_amc_micro
replace arrival_time_2000_amc_micro = arrival_time_1990_amc_micro if arrival_time_2000_amc_micro > arrival_time_1990_amc_micro
replace arrival_time_2010_amc_micro = arrival_time_2000_amc_micro if arrival_time_2010_amc_micro > arrival_time_2000_amc_micro

save "$temp\traveltime_micro", replace


*** Meso ***
import delimited "$input\fmm_amc_meso.csv", clear
rename amc_mesomesorregi meso
drop v1

save "$temp\traveltime_meso", replace