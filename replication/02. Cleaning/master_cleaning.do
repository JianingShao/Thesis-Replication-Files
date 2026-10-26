/*==============================================================================
Project: EC331 Quantitative Thesis - master file for data cleaning
Author: Jianing Shao

Outline:
    0. Setup
    I.    Unit of Analysis          01.mapping.do
    II.   Employment                02.employment.do
    III.  Population & GDP          03.gdp_pop.do
    IV.   Geographical Traits       04.controls.do
    V.    Travel Time               05.traveltime.do
    VI.   Agricultural Land Shares  06.landshare.do
    VII.  Product Classification    07.classify.R        (R, run outside Stata)
    VIII. Product Categories        08.categories.do
    IX.   Aggregation               09.aggregation.do

STRUCTURE. Every script except IX writes only to $temp. Script IX is the single
place that assembles 03. Final Datasets, which holds exactly three files, one
per unit of analysis:
    micro.dta       531 micro-regions
    meso.dta        132 meso-regions
    croppanel.dta   traded crop x micro-region
All downstream analysis reads only those three.

ORDER MATTERS. VI must precede VII (the classifier needs value per ton from the
land-share panel), VII must precede VIII, and IX is last because it merges what
VIII produces. Aggregation used to run at position VII, which is why the
category build could not be merged in and instead rewrote micro.dta after the
fact.

ARCHIVED. 02.commodity.do built soy/cotton/cattle from soy.xls, cotton.xls and
cattle.xls -- a separate source from the PAM/PPM pulls, measuring production
where the category columns measure harvested area. All crop data now comes from
PAM/PPM through 06.landshare.do. See 02. Cleaning/archive/.
================================================================================*/

*------------------------------- Setup -----------------------------------------*

version 18
clear all
set more off, perm
cap log close

* Create directories
global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input = "$root\01. Raw Data"
global temp = "$root\02. Cleaning\temp"
global output = "$root\03. Final Datasets"
global code = "$root\02. Cleaning"


*------------- I. Unit of Analysis ------------------------*
*******************************************
**** AMC generation from IBGE data     ****
**** version 1.0  24.06.2015           ****
**** Ehrl (2017) Estudos Economicos 47/1 **
*******************************************

*** Period 1970 - 2010 ***

*** data preperation ***
do "$code\amc\_Crosswalk_pre.do"

*** main procedure ***
do "$code\amc\_Crosswalk_main.do"

*** Mapping ***
do "$code\01.mapping.do"

*-------------- II. Employment -------------------*
do "$code\02.employment.do"

*------------- III. Population & GDP --------------------*
do "$code\03.gdp_pop.do"

*------------- IV. Geographical Characteristics ------------------*
do "$code\04.controls.do"

*------------ V. Travel Time -----------------------*
do "$code\05.traveltime.do"

*------------- VI. Agricultural Land Shares --------------------*
* Requires the SIDRA pulls from 00.pam_pull.R in $input\pam\
do "$code\06.landshare.do"

*------------- VII. Product Classification --------------------*
* FAOSTAT export-orientation ratio (defines traded status) and the settled gap
* rule on value per ton. Both are R scripts, run outside Stata:
*   Rscript "01b.faostat_pull.R"   -> 01. Raw Data\faostat\ex_ratio.csv
*   Rscript "07.classify.R"        -> temp\products.dta
* 07 stops with an error if any crop lands on the wrong side of the
* 1,000 / 2,000 R$ per ton thresholds, or if the group counts move off the
* settled 3 / 5 / 6 / 1.

*------------- VIII. Product Categories --------------------*
do "$code\08.categories.do"

*------------- IX. Aggregation --------------------*
do "$code\09.aggregation.do"
