
*******************************************
**** Auxiliary file 2: "matching.do"   ****
**** matching of cluster-numbers       ****
*******************************************
**** Ehrl (2017) Estudos Economicos 47/1 ** 
*******************************************

*** save the current data in use (to restore it later)
save "$temp\current.dta", replace

*** keep only the two different group numbers
keep clu`1' clu_new
keep if clu_new!=.
sort clu`1' clu_new
** drop unecessary obs:
drop if clu`1'==clu_new
drop if clu`1'==clu`1'[_n-1] & clu_new==clu_new[_n-1]

*** 1. check
*** problem for several destinies (to be replaced by only 1 new clu-number)
 count if clu`1'==clu`1'[_n-1]
 while r(N)!=0 {
	replace clu`1'=clu_new if clu`1'==clu`1'[_n-1]
	replace clu_new=clu_new[_n-1] if clu_new==clu`1'
	sort clu`1' clu_new
	// drop double obs. (in case)
	drop if clu`1'==clu_new
	drop if clu`1'==clu`1'[_n-1] & clu_new==clu_new[_n-1]
	// to end the loop:
	count if clu`1'==clu`1'[_n-1]
}
 save "$temp\temp.dta", replace
 
 *** 2. check if a problem will occur:
 *** problem for cross-ref (a new cluster number is at the same time replaced by another new one)
 preserve 
 rename clu_new help
 rename clu`1' clu_new
 append using "$temp\temp.dta"
 gsort clu_new -help, mfirst
 count if clu_new==clu_new[_n+1] & help[_n+1]!=.
// if yes:
 if r(N)!=0 {
restore

rename clu_new clu_new2 
rename clu`1' clu_new
save "$temp\temp2.dta", replace
use "$temp\temp.dta", clear
merge m:1 clu_new using "$temp\temp2.dta", nogen
replace clu_new2=clu_new if clu_new2==.
keep if clu`1'!=.
drop clu_new
rename clu_new2 clu_new 
sort clu`1' clu_new
// drop unecessary obs:
drop if clu`1'==clu_new
drop if clu`1'==clu`1'[_n-1] & clu_new==clu_new[_n-1]
save "$temp\temp.dta", replace
}
// if no:
else {
restore
}

*** repeat this procedure several times

*** 1. check:
count if clu`1'==clu`1'[_n-1]
while r(N)!=0 {
	replace clu`1'=clu_new if clu`1'==clu`1'[_n-1]
	replace clu_new=clu_new[_n-1] if clu_new==clu`1'
	sort clu`1' clu_new
	// drop double obs. (in case)
	drop if clu`1'==clu_new
	drop if clu`1'==clu`1'[_n-1] & clu_new==clu_new[_n-1]
	// to end the loop:
	count if clu`1'==clu`1'[_n-1]
}
 
*** 2. check if a problem will occur
 preserve 
 cap drop help
 rename clu_new help
 rename clu`1' clu_new
 append using "$temp\temp.dta"
 gsort clu_new -help, mfirst
 count if clu_new==clu_new[_n+1] & help[_n+1]!=.
// if yes:
 if r(N)!=0 {
 restore

rename clu_new clu_new2 
rename clu`1' clu_new
save "$temp\temp2.dta", replace
use "$temp\temp.dta", clear
merge m:1 clu_new using "$temp\temp2.dta", nogen
replace clu_new2=clu_new if clu_new2==.
keep if clu`1'!=.
drop clu_new
rename clu_new2 clu_new 
sort clu`1' clu_new
// drop unecessary obs:
drop if clu`1'==clu_new
drop if clu`1'==clu`1'[_n-1] & clu_new==clu_new[_n-1]
save "$temp\temp.dta", replace
}
// if no
else {
restore
}

*** 1. check:
count if clu`1'==clu`1'[_n-1]
while r(N)!=0 {
	replace clu`1'=clu_new if clu`1'==clu`1'[_n-1]
	replace clu_new=clu_new[_n-1] if clu_new==clu`1'
	sort clu`1' clu_new
	// drop double obs. (in case)
	drop if clu`1'==clu_new
	drop if clu`1'==clu`1'[_n-1] & clu_new==clu_new[_n-1]
	// to end the loop:
	count if clu`1'==clu`1'[_n-1]
}
 
*** 2. check if a problem will occur
 preserve 
 cap drop help
 rename clu_new help
 rename clu`1' clu_new
 append using "$temp\temp.dta"
 gsort clu_new -help, mfirst
 count if clu_new==clu_new[_n+1] & help[_n+1]!=.
// if yes:
 if r(N)!=0 {
 restore

rename clu_new clu_new2 
rename clu`1' clu_new
save "$temp\temp2.dta", replace
use "$temp\temp.dta", clear
merge m:1 clu_new using "$temp\temp2.dta", nogen
replace clu_new2=clu_new if clu_new2==.
keep if clu`1'!=.
drop clu_new
rename clu_new2 clu_new 
sort clu`1' clu_new
// drop unecessary obs:
drop if clu`1'==clu_new
drop if clu`1'==clu`1'[_n-1] & clu_new==clu_new[_n-1]
save "$temp\temp.dta", replace
}
// if no
else {
restore
}

*** final checks:
assert clu`1'!=clu`1'[_n-1]
 preserve 
 cap drop help
 rename clu_new help
 rename clu`1' clu_new
 append using "$temp\temp.dta"
 gsort clu_new -help, mfirst
 count if clu_new==clu_new[_n+1] & help[_n+1]!=.
 assert r(N)==0
 restore

// procedure is complete. restore data
use "$temp\current.dta", clear

*** finally, replace cluster number of all mun of one group
*** with the new number of the other group
drop clu_new
merge m:1 clu`1' using "$temp\temp.dta", nogen
replace clu`1'=clu_new if clu_new!=.
drop clu_new

erase "$temp\temp.dta"
erase "$temp\current.dta"
cap erase "$temp\temp2.dta"
