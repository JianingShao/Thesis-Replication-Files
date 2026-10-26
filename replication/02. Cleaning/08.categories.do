/*==============================================================================
PURPOSE:  Aggregate PAM/PPM products into the settled categories, and build the
          crop x micro-region panel. Follows the pipeline convention: writes to
          $temp only. 09.aggregation.do is the single place that assembles the
          final datasets.

          Categories come from category_ex5 in temp/products.dta, written by
          07.classify.R:
            exp_sensitive    soy, castor, sisal
            exp_insensitive  coffee, cocoa, tobacco, pepper, walnut
            exp_processed    sugarcane, orange, cashew, peanut, cotton (both)
            pasture          cattle pasture equivalent (= head count, 1 head/ha)
            domestic         everything else
          All five stay in the land denominator; only the first two are the
          treatment/control pair of the specialization test.

          YEAR LABELS. PAM municipality data begins in 1974 and the survey years
          are 1974, 1980, 1991, 2000, 2010. Columns leave this script on those
          survey years -- sens1974, sens1991 -- and 09.aggregation.do relabels
          them to the common decadal grid along with every other series, so the
          convention is stated in exactly one place. After aggregation,
          sens1970 is the 1974 harvest and sens1990 is 1991.

          UNITS. area_ha is hectares for crops and head of cattle for pasture
          (06.landshare.do sets area = head / stocking_rate with a rate of 1).
          Quantity aggregates are built ONLY for the two traded categories,
          where every member crop is measured in tonnes. Domestic mixes tonnes
          with thousands of fruit and bunches, and IBGE reports no output
          quantity for pasture at all, so a summed quantity would be
          meaningless for both and is deliberately not created.

INPUT:    $temp\products.dta            (from 07.classify.R)
          $temp\landshare_micro.dta     (from 06.landshare.do)
          $temp\landshare_meso.dta
OUTPUT:   $temp\category_micro.dta      wide category columns, one row per micro
          $temp\category_meso.dta       same at meso
          $temp\croppanel_micro.dta     crop x micro long panel, traded crops
==============================================================================*/

*----------------- 1. Category aggregates, both levels -----------------------*

foreach lvl in micro meso {

    use "$temp\landshare_`lvl'.dta", clear
    keep `lvl' year product area_ha quantity

    * Anything unmatched would silently leave the denominator, so report it and
    * fold it into domestic rather than dropping it.
    merge m:1 product using "$temp\products.dta", keep(1 3) keepusing(category_ex5)
    quietly count if _merge == 1
    if r(N) > 0 {
        di as error "  WARNING (`lvl'): " r(N) " product-year rows unmatched " ///
            "in products.dta; assigned to domestic. Products:"
        quietly levelsof product if _merge == 1, local(unm)
        foreach p of local unm {
            di as error "      `p'"
        }
        replace category_ex5 = "domestic" if _merge == 1
    }
    drop _merge

    * Quantity only where summing tonnes is meaningful (see header).
    gen double qty_traded = quantity ///
        if inlist(category_ex5, "exp_sensitive", "exp_insensitive")

    gen byte cat = .
    replace cat = 1 if category_ex5 == "exp_sensitive"
    replace cat = 2 if category_ex5 == "exp_insensitive"
    replace cat = 3 if category_ex5 == "pasture"
    replace cat = 4 if category_ex5 == "domestic"
    replace cat = 5 if category_ex5 == "exp_processed"

    collapse (sum) area_ha (sum) qty_traded, by(`lvl' year cat)

    * Total agricultural land is the sum over every category, processed
    * included: it is the denominator of the land share, not a test outcome.
    bysort `lvl' year: egen double agland = total(area_ha)

    reshape wide area_ha qty_traded, i(`lvl' year agland) j(cat)
    rename area_ha1 sens
    rename area_ha2 ins
    rename area_ha3 past
    rename area_ha4 dom
    rename area_ha5 proc
    rename qty_traded1 qsens
    rename qty_traded2 qins
    drop qty_traded*

    foreach v in sens ins past dom proc {
        replace `v' = 0 if missing(`v')
        gen double sh`v' = `v' / agland
    }

    * Total CROPLAND: every crop, pasture excluded. This is the anchor column
    * of the category table. Pasture is not measured land -- 06.landshare.do
    * converts head of cattle at one head per hectare -- and it is roughly
    * three quarters of agland, so an anchor including it is close to a
    * restatement of the pasture column (corr 0.92 in the long difference,
    * against 0.55 for cropland).
    gen double cropland = agland - past

    * NB years stay on their PAM survey values here (1974, 1991). The relabel
    * to the common decadal grid is applied once, in 09.aggregation.do, the
    * same way it is applied to the census series -- see the header.
    keep `lvl' year agland cropland sens ins past dom proc ///
        shsens shins shpast shdom shproc qsens qins
    reshape wide agland cropland sens ins past dom proc ///
        shsens shins shpast shdom shproc qsens qins, i(`lvl') j(year)

    foreach y in 1974 1980 1991 2000 2010 {
        capture label var agland`y'   "Total agricultural land incl. pasture, ha"
        capture label var cropland`y' "Total cropland, pasture excluded, ha"
        capture label var sens`y'     "Transport-cost-sensitive crop area, ha"
        capture label var ins`y'      "Transport-cost-insensitive crop area, ha"
        capture label var past`y'     "Pasture equivalent = cattle head count"
        capture label var dom`y'      "Domestic crop area, ha"
        capture label var proc`y'     "Processed/excluded traded crop area, ha"
        capture label var qsens`y'    "Sensitive crop output, tonnes"
        capture label var qins`y'     "Insensitive crop output, tonnes"
    }

    * Match the naming convention of the other temp files, which 09 strips.
    foreach v of varlist agland* cropland* sens* ins* past* dom* proc* ///
        sh* qsens* qins* {
        rename `v' `v'_`lvl'
    }

    sort `lvl'
    save "$temp\category_`lvl'.dta", replace
}

*----------------- 1a. Prevalence, back into products.dta --------------------*
* Share of micro-regions recording positive area in the base year. Used by the
* appendix classification table.

use "$temp\landshare_micro.dta", clear
keep if year == 1974
gen byte pos = area_ha > 0

* denominator: number of micro-regions in the base year
preserve
keep micro
duplicates drop
quietly count
local nmicro = r(N)
restore

collapse (sum) pos, by(product)
gen double prev1974 = 100 * pos / `nmicro'
label var prev1974 "% of micro-regions with positive area, 1974"
drop pos
tempfile prv
save `prv'

use "$temp\products.dta", clear
capture drop prev1974
merge 1:1 product using `prv', keep(1 3) nogen
replace prev1974 = 0 if missing(prev1974)
save "$temp\products.dta", replace

*----------------- 1b. Named single crops ------------------------------------*
* Soybean and coffee as individual columns, for the descriptive table.
* Cattle is already carried as pasture. Harvested area, matching the category
* columns; years stay on the PAM grid and are relabelled in 09.

use "$temp\landshare_micro.dta", clear
keep if inlist(product, "Soja (em grão)", "Café (em grão) Total")
gen str6 crop = cond(strpos(product, "Soja") > 0, "soy", "coffee")
collapse (sum) area_ha, by(micro year crop)
reshape wide area_ha, i(micro year) j(crop) string
rename area_hasoy    soy
rename area_hacoffee coffee
foreach v of varlist soy coffee {
    replace `v' = 0 if missing(`v')
}
reshape wide soy coffee, i(micro) j(year)
foreach y in 1974 1980 1991 2000 2010 {
    capture label var soy`y'    "Soybean harvested area, ha"
    capture label var coffee`y' "Coffee harvested area, ha"
}
foreach v of varlist soy* coffee* {
    rename `v' `v'_micro
}
sort micro
save "$temp\namedcrop_micro.dta", replace

*----------------- 2. Crop x micro-region panel ------------------------------*
* The unit of analysis for the pooled-tau test: one row per traded crop per
* micro-region, long difference 1974-2010. Kept as its own dataset because it
* is its own unit of observation, exactly as meso is.

use "$temp\landshare_micro.dta", clear
keep if inlist(year, 1974, 2010)
merge m:1 product using "$temp\products.dta", keep(3) nogen ///
    keepusing(category_ex5 vpt lnvpt)
keep if inlist(category_ex5, "exp_sensitive", "exp_insensitive")

keep micro product category_ex5 vpt lnvpt year area_ha quantity total_agland
gen double share = area_ha / total_agland
reshape wide area_ha quantity share total_agland, i(micro product) j(year)

* A crop absent from a micro-region-year is a true zero, not missing: PAM
* records the municipality, so a blank is no recorded area.
foreach v of varlist area_ha1974 area_ha2010 share1974 share2010 {
    replace `v' = 0 if missing(`v')
}

gen double dlnarea = ln(area_ha2010 + 1) - ln(area_ha1974 + 1)
gen double dshare  = share2010 - share1974
gen byte   sens    = category_ex5 == "exp_sensitive"
egen prodid = group(product)

label var dlnarea "D log(harvested area + 1), 1974-2010"
label var dshare  "D land share, 1974-2010"
label var sens    "1 = transport-cost-sensitive category"
label var lnvpt   "ln national value per ton, 2010 (continuous tau proxy)"
label var prodid  "Product identifier"

order micro product prodid category_ex5 sens vpt lnvpt
sort micro prodid
save "$temp\croppanel_micro.dta", replace

di as result ""
di as result "=== 08.categories: crop x micro panel ==="
quietly levelsof product, local(ps)
local n : word count `ps'
di as result "    traded crops: `n'"
quietly count
di as result "    rows: " r(N)
quietly levelsof micro, local(ms)
local nm : word count `ms'
di as result "    micro-regions: `nm'"
