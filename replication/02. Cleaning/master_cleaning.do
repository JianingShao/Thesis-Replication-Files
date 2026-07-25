/*==============================================================================
Project: EC331 Quantitative Thesis - master file for data cleaning
Author: Jianing Shao
	
Outline:
	0. Setup
	I. Unit of Analysis
	II. Commondity Production
	III. Employment
	IV. Population & GDP
	V. Geographical Characteristics
	VI. Travel Time
	VII. Data Aggregation
	VIII. Agricultural Land Shares
================================================================================*/

*------------------------------- Setup -----------------------------------------*

version 18
clear all                                                       
set more off, perm
cap log close

* Create directories
global root "C:\Users\JianingShao\OneDrive - London School of Economics\Thesis\replication"
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

*-------------- II. Commondity Production --------------*
do "$code\02.commodity.do"

*-------------- III. Employment -------------------*
do "$code\03.employment.do"

*------------- IV. Population & GDP --------------------*
do "$code\04.gdp_pop.do"

*------------- V. Geographical Characteristics ------------------*
do "$code\05.controls.do"

*------------ VI. Travel Time -----------------------*
do "$code\06.traveltime.do"

*------------- VII. Data Aggregation --------------------*
do "$code\07.aggregation.do"

*------------- VIII. Agricultural Land Shares --------------------*
* Requires the SIDRA pulls from 00.pam_pull.R in $input\pam\
do "$code\08.landshare.do"

*------------- IX. Product Classification --------------------*
* FAOSTAT export-orientation ratio (defines traded status) and the
* rule-based product grouping used in the specialization analysis.
* 01b and 09 are R scripts, run outside Stata:
*   Rscript "01b.faostat_pull.R"   -> ex_ratio.csv
*   Rscript "09.classify_rule.R"   -> product_class.csv (category_ex5)
