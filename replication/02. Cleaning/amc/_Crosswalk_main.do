
*******************************************
**** AMC generation from IBGE data     ****
**** version 1.0  24.06.2015           ****
**** Ehrl (2017) Estudos Economicos 47/1 ** 
*******************************************
*******************************************
**** part 2: main procedure            ****
*******************************************
**** (10) define period for AMCs
**** may be a combination of any two census
**** yearsto be chosen by the user
local startyear = 1970
local endyear = 2010
*******************************************

local y0=`startyear'

*****************************************************
*** (18) loop over all years until endyear is reached
while `y0' != `endyear' {

** save results in separate log-files
cap log close
log using "$temp\_Crosswalk_`startyear'_`endyear'_`y0'.log", replace

** chose data set
if `y0' == `startyear' {
use "$temp\_Crosswalk_pre.dta", clear
}
else {
use "$temp\_Crosswalk_`y_1'.dta", clear
}

** define the following Census year
if `y0'==1872 {
local y1=1900
}
if `y0'==1900 {
local y1=1911
}
if `y0'==1911 {
local y1=1920
}
if `y0'==1920 {
local y1=1933
}
if `y0'==1933 {
local y1=1940
}
if `y0'==1940 {
local y1=1950
}
if `y0'==1950 {
local y1=1960
}
if `y0'==1960 {
local y1=1970
}
if `y0'==1970 {
local y1=1980
}
if `y0'==1980 {
local y1=1991
}
if `y0'==1991 {
local y1=2000
}
if `y0'==2000 {
local y1=2010
}

*******************************************************
*** (11) assign all new mun a number of missing matches
gen ch_match=n_dest`y0'

*** define max. #destinies 
foreach n of numlist 2/5{
count if n_dest`y0'==`n'
global n_dest`n'=r(N)
global match_dest`n'=0
}

**************************************
*** (12) generate the new cluster-var.
// only for the first period:
if `y0' == `startyear' {
	// important to distinguish the AMC (mun may have same names)
	gsort uf_amc dest1`y0' -exist_d`y0' final_name
	egen clu`y0'=group(uf_amc dest1`y0')
	// the first cluster assignment of the data set --> keep this var. until the end
	gen clu`y0'_orig=clu`y0'
}
// other periods:
else {
	// builds on the exsting groups from the prior period
	gen clu`y0'=clu`y_1'_final
	gsort clu`y0' -dest1`y0' code2010
	// assign all new-`y0'-mun a new number 
	replace clu`y0'=clu`y0'[_n-1]+1 if dest1`y0'!="" & clu`y0'==.
}	

** mun with destiny/origin outside their own UF_amc
// these mun will not only be matched later on
replace ch_match=ch_match-1 if code2010==2205706 & `y0'==1872
replace ch_match=ch_match-1 if code2010==4204202 & `y0'==1911
replace ch_match=ch_match-1 if code2010==4209003 & `y0'==1911
replace ch_match=ch_match-1 if code2010==4213609 & `y0'==1911
replace ch_match=ch_match-1 if code2010==4208104 & `y0'==1911
replace ch_match=ch_match-1 if code2010==4210100 & `y0'==1911
replace ch_match=ch_match-1 if code2010==1100205 & `y0'==1911


**********************************************
*** (13) begin procedure: 
*** assign new cluster number to 1. destinies
gen clu_new=.
gsort uf_amc dest1`y0' -exist_d`y0' final_name
replace clu_new=clu`y0'[_n-1] if dest1`y0'==dest1`y0'[_n-1] & clu`y0'[_n-1]!=. & dest1`y0'!=""
*** replace the clu-number of the new mun. 
// more than one mun may emerge from the same origin:
replace clu_new=clu_new[_n-1] if dest1`y0'==dest1`y0'[_n-1] & clu_new[_n-1]!=.
*** subtract 1 from the number of missing matches:
replace ch_match=ch_match - 1 if clu_new!=.

*** (15) generate consistent clusters
do "$code\amc\matching.do" "`y0'"

di "missing matches per group #1"
tab ch_match


foreach p of numlist 2 3 4 5 {

**********************************************************
*** (16) include those with a different dest`p'
// i.e. those that have `p' different origins/destinations
count if n_dest`y0'==`p'
if r(N) > 0 {

*** (13) repeat procedure above:
gen mis`y0'=dest`p'`y0' if n_dest`y0'>=`p'
*** dummy for those mun:
gen target= mis`y0'!=""
gen clu_new=.

*** (14) try mun-name from next period:
replace mis`y0'=dest1`y1' if target==0 & exist_d`y1'==1 
gsort uf_amc mis`y0' -target final_name
replace clu_new=clu`y0'[_n+1] if mis`y0'==mis`y0'[_n+1] & clu`y0'[_n+1]!=. & target==1

// may not work bc. mun name in `y0' and `y0' are different. try with mun-name of current period
*** overwrite entry of mis`y0' but do NOT OVERWRITE clu_new in case there has been a matching already
replace mis`y0'=dest1`y0' if target==0 & exist_d`y0'==1
gsort uf_amc mis`y0' -target final_name
replace clu_new=clu`y0'[_n+1] if mis`y0'==mis`y0'[_n+1] & clu`y0'[_n+1]!=. & target==1 & clu_new==.
	
// may not work bc. mun name in `y0' and `y1' are still different. try with the final_name
*** --> overwrite entry of mis`y0' but do NOT OVERWRITE clu_new in case there has been a matching
replace mis`y0'=final_name if target==0
gsort uf_amc mis`y0' -target final_name
replace clu_new=clu`y0'[_n+1] if mis`y0'==mis`y0'[_n+1] & clu`y0'[_n+1]!=. & target==1 & clu_new==.

*** (11) adjust the ch_match for matches:
count if clu_new!=.
global match_dest`p'=r(N)
replace ch_match=ch_match-1 if clu_new!=.
drop target mis`y0'

*** (15) apply matching between old and new cluster numbers
do "$code\amc\matching.do" "`y0'"

di "missing matches per group #`p'"
tab ch_match

if `p'==2 {
assert $match_dest2==$n_dest2 + $n_dest3 + $n_dest4 + $n_dest5
}
if `p'==3 {
assert $match_dest3==$n_dest3 + $n_dest4 + $n_dest5
}
if `p'==4 {
assert $match_dest4== $n_dest4 + $n_dest5
}
if `p'==5 {
assert $match_dest5==$n_dest5
}

}
}

*********************************************************************
*** (14) procedure for dest1, bc not all groups may be matched so far
// these are the ones to be matched:
gen mis`y0'=dest1`y0' if ch_match>0
*** dummy for those mun:
gen target= mis`y0'!=""
gen clu_new=.

// try possible matching partners from next period
*** replace with muname, otherwise the mun may not yet exist in current period or may be desmembr. of that mun in the next period
replace mis`y0'=muname`y1' if target==0 & muname`y1'!=""
gsort uf_amc mis`y0' -target final_name
replace clu_new=clu`y0'[_n+1] if mis`y0'==mis`y0'[_n+1] & clu`y0'[_n+1]!=. & target==1

// may not work bc. mun name in `y0' and `y1' are still different. try with the final name
// --> overwrite entry of mis`y0' but do NOT OVERWRITE clu_new in case there has been a matching
// only replace those there are NOT required to be matched, considering the previous matching round already.
replace mis`y0'=final_name if target==0 | clu_new!=.
gsort uf_amc mis`y0' -target -clu_new final_name, mfirst
replace clu_new=clu`y0'[_n+1] if mis`y0'==mis`y0'[_n+1] & clu`y0'[_n+1]!=. & target==1 & clu_new==.

*** (11) adjust the ch_match for matches:
replace ch_match=ch_match - 1 if clu_new!=.
drop target mis`y0'

*** (15) apply matching between old and new cluster numbers
do "$code\amc\matching.do" "`y0'"

di "missing matches per group"
tab ch_match


******************************
*** crossref problem:
// may occur in rare occasions 
count if ch_match!=0
if r(N) != 0 { 

// i.e. two mun are created at the same time and both refer their origin to the other
// is at least the case for "Sao Goncalo / Macahyba" in 1872 (RN)
// these are the ones to be matched:
gen mis`y0'=dest1`y0' if ch_match>0
sort uf_amc mis`y0'
*** replace only the second in each uf_amc group
replace mis`y0'=dest1`y1' if mis`y0'!="" & mis`y0'[_n-1]!="" & uf_amc==uf_amc[_n-1]
gen clu_new=.
replace clu_new=clu`y0'[_n-1] if mis`y0'==mis`y0'[_n-1] & clu`y0'[_n-1]!=. & mis`y0'!="" & ch_match!=0 
*** adjustment for both ch_match
replace ch_match=ch_match - 1 if mis`y0'==mis`y0'[_n-1] & clu`y0'[_n-1]!=. & mis`y0'!="" & ch_match!=0 
replace ch_match=ch_match - 1 if mis`y0'==mis`y0'[_n+1] & clu`y0'[_n+1]!=. & mis`y0'!="" & ch_match!=0 

do "$code\amc\matching.do" "`y0'"

di "missing matches per group"
tab ch_match
}

**********************
*** (17) last check:
assert ch_match==0
// everything matched
**********************


*** new cluster-var for next period
egen clu`y0'_final=group(clu`y0')
sort clu`y0'_final
order uf_amc final_name muname`y0' clu`y0' clu`y0'_final
sum clu*_final

*** clear up data from current period
drop dest1`y0' dest2`y0' n_dest`y0' exist_d`y0' dest3`y0' dest4`y0' dest5`y0' ch_match

*** save
order uf_amc clu`y0' code2010
compress
save "$temp\_Crosswalk_`y0'.dta", replace

*** define the new years and begin next loop
local y_1 = `y0'
local y0 = `y1'

log close
}





************************************
***** final changes in the procedure
************************************

cap log close

*** use the last generated data set
use "$temp\_Crosswalk_`y_1'.dta", clear

*** drop unecessary information:
keep uf_amc code2010 final_name clu*_final


*** solve remaining problems
** generate auxiliary cluster variable
gen clu`y_1'_final2=clu`y_1'_final

** last changes (semi-manual)
// see "_Crosswalk_pre.do" - destiny/origin outside their own UF_amc
if `startyear'<=1872 {
sum clu`y_1'_final if code2010==2205706
local n1 = r(mean)
sum clu`y_1'_final if final_name=="Granja"
local n0 = r(mean)
recode clu`y_1'_final2 (`n1' = `n0')
}

if `startyear'<=1911 & `endyear'>=1911 {
sum clu`y_1'_final if code2010==4204202
local n1 = r(mean)
sum clu`y_1'_final if code2010==4209003
local n2 = r(mean)
sum clu`y_1'_final if code2010==4213609
local n3 = r(mean)
sum clu`y_1'_final if final_name=="Palmas" & uf_amc==15
local n0 = r(mean)
recode clu`y_1'_final2 (`n1' `n2' `n3' = `n0')

sum clu`y_1'_final if code2010==4208104
local n1 = r(mean)
sum clu`y_1'_final if code2010==4210100
local n2 = r(mean)
sum clu`y_1'_final if final_name=="Rio Negro" & uf_amc==15
local n0 = r(mean)
recode clu`y_1'_final2 (`n1' `n2' = `n0')

sum clu`y_1'_final if code2010==1100205
local n1 = r(mean)
sum clu`y_1'_final if final_name=="Humaita" & uf_amc==1
local n0 = r(mean)
recode clu`y_1'_final2 (`n1' = `n0')
}

// litigo MG/ES
if `startyear'<=1940 | `endyear'>=1960 {
sum clu`y_1'_final if code2010==3203304
local n1 = r(mean)
sum clu`y_1'_final if code2010==3200904
local n2 = r(mean)
sum clu`y_1'_final if code2010==3104700
local n0 = r(mean)
recode clu`y_1'_final2 (`n1' `n2' = `n0')
}

sort uf_amc 
egen clu_final=group(clu`y_1'_final2)
drop clu`y_1'_final2


******************************************
*** generate a new code for the final AMCs

*** generate common UF_AMCs first
recode uf_amc (1 20=1) (4 5=4) (6=5) (7=6) (8=7) (9=8) (10=9) ///
	(11=10) (12 18=11) (13=12) (14=13) (15 16=14) (17=15) (19=16)
label define uf_amc_lb 1 "AM/MT/(RO/RR/MS)" 2 "PA/(AP)" 3 "MA" ///
	4 "PI/CE" 5 "RN" 6 "PB" 7 "PE" 8 "AL" ///
	9 "SE" 10 "BA" 11 "ES/MG"  12 "RJ" 13 "SP"  14 "PR/SC"  15 "RS" 16 "GO/(DF/TO)" 
label values uf_amc uf_amc_lb

*** assign a new cluster number, with UF in first 2 digits
*** the next two digits refer to the alpabethical position of the mun in an AMC

bysort uf_amc clu_final (code2010): gen help = 1 if _n==1 & clu_final!=.
bysort help uf_amc (code2010): gen amc_n=_n if help==1
// assign to all other members of the AMC
sort uf_amc clu_final code2010
replace amc_n=amc_n[_n-1] if amc_n==.

gen amc = uf_amc*1000 if clu_final!=.
replace amc=amc + amc_n
drop amc_n help

sum amc clu_final

*** save final data
sort uf_amc clu_final final_name
order uf_amc final_name clu_final amc
save "$temp\_Crosswalk_final_`startyear'_`endyear'.dta", replace



