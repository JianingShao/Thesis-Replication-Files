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
================================================================================*/

*------------------------------- Setup -----------------------------------------*

version 18.5
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
