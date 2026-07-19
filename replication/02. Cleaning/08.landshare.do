/*==============================================================================
PURPOSE:  Construct micro-region agricultural land shares l_g (the outcome of
          the specialization proposition) from the PAM/PPM pulls produced by
          00.pam_pull.R.

          Land in product g = harvested area (crops, PAM 1612 + 1613) or
          pasture-equivalent area (cattle, PPM 3939 herd / stocking rate).
          l_g = area_g / total agricultural area in the micro-region-year.

INPUT:    $input\pam\pam_temporary.csv
          $input\pam\pam_permanent.csv
          $input\pam\ppm_cattle.csv
          $temp\mapping.dta                 (from 01.mapping.do)
OUTPUT:   $temp\landshare_micro.dta         (micro x year x product)
          $temp\landshare_meso.dta          (meso  x year x product)

NOTES:    1. Missing area for a municipality-year-product reflects either a
             municipality not yet created (its area is recorded under the
             parent municipality) or zero/unsurveyed production. Both are set
             to zero: after aggregation to minimum-comparable-area-based
             micro-regions, parent and children sum into the same unit, so
             the panel is consistent across boundary changes.
          2. Stocking rate converts cattle head to pasture-equivalent
             hectares; the baseline of 1 head/ha is an assumption and can be
             changed via the global below.
          3. PAM years are 1974, 1980, 1991, 2000, 2010 (municipality-level
             PAM starts in 1974, so 1974 stands in for the 1973 survey year
             used elsewhere).
==============================================================================*/

* Stocking-rate assumption (head of cattle per hectare of pasture)
global stocking_rate = 1

*----------------- 1. Crops: temporary + permanent ---------------------------*

import delimited "$input\pam\pam_permanent.csv", clear varnames(1) encoding(utf-8)
tempfile perm
save `perm'

import delimited "$input\pam\pam_temporary.csv", clear varnames(1) encoding(utf-8)
append using `perm'

rename code7 code2010

* CSVs from R encode missing values as the string "NA": convert to numeric
foreach v of varlist area_ha quantity value_prod {
    capture confirm string variable `v'
    if !_rc {
        quietly replace `v' = "" if `v' == "NA"
        destring `v', replace
    }
}
replace area_ha = 0 if missing(area_ha)

merge m:1 code2010 using "$temp\mapping.dta", keep(3) nogen ///
    keepusing(micro meso uf sigla region)

collapse (sum) area_ha quantity value_prod, by(micro meso year product)
tempfile crops_micro
save `crops_micro'

*----------------- 2. Pasture-equivalent area from cattle --------------------*

import delimited "$input\pam\ppm_cattle.csv", clear varnames(1) encoding(utf-8)
rename code7 code2010
capture confirm string variable head
if !_rc {
    quietly replace head = "" if head == "NA"
    destring head, replace
}
replace head = 0 if missing(head)
gen area_ha = head / $stocking_rate
gen product = "Pastagem (equivalente, bovinos)"

merge m:1 code2010 using "$temp\mapping.dta", keep(3) nogen ///
    keepusing(micro meso uf sigla region)

collapse (sum) area_ha head, by(micro meso year product)
append using `crops_micro'

*----------------- 3. Land shares --------------------------------------------*

bysort micro year: egen total_agland = total(area_ha)
gen landshare = area_ha / total_agland
label var area_ha      "Harvested or pasture-equivalent area (ha)"
label var total_agland "Total agricultural land in micro-region-year (ha)"
label var landshare    "l_g: share of agricultural land in product g"

* Land shares excluding pasture (crops-only denominator), for robustness
bysort micro year: egen total_cropland = ///
    total(cond(product != "Pastagem (equivalente, bovinos)", area_ha, 0))
gen landshare_crops = area_ha / total_cropland ///
    if product != "Pastagem (equivalente, bovinos)"
label var landshare_crops "l_g among crops only (pasture excluded)"

save "$temp\landshare_micro.dta", replace

*----------------- 4. Meso-region aggregation (robustness) -------------------*

collapse (sum) area_ha, by(meso year product)
bysort meso year: egen total_agland = total(area_ha)
gen landshare = area_ha / total_agland
label var landshare "l_g: share of agricultural land in product g (meso)"
save "$temp\landshare_meso.dta", replace
