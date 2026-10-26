/*==============================================================================
Project: EC331 Quantitative Thesis - analysis
Author: Jianing Shao

Outline:
    0. Setup
    I. Tables
	II. Figures
================================================================================*/


*------------------------------- Setup -----------------------------------------*

version 18
clear all                                                       
set more off, perm
cap log close

* Create directories
global root "C:\Users\JianingShao\Documents\GitHub\thesis-issue3\replication"
global input = "$root\03. Final Datasets"
global output = "$root\05. Tables and Figures"
global code = "$root\04. Analysis"

* Three final datasets, one per unit of analysis:
*   micro.dta       531 micro-regions          -- T1, T2, T3, T5, T6, T7, T8
*   meso.dta        132 meso-regions           -- T9 Panel C
*   croppanel.dta   traded crop x micro-region -- T4
* Tables that need meso or croppanel load them where required.

* main dataset in use at micro-region level
use "$input\micro.dta", clear

*--------------- I. Tables -------------------------*
do "$code\01.Tables.do"

*--------------- II. Figures -------------------------*
do "$code\03.programs.do"

do "$code\02.Figures.do"

