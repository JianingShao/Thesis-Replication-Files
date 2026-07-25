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
global root "C:\Users\JianingShao\OneDrive - London School of Economics\Thesis\replication"
global input = "$root\03. Final Datasets"
global output = "$root\05. Tables and Figures"
global code = "$root\04. Analysis"

* main dataset in use at micro-region level
use "$input\micro.dta", clear

*--------------- I. Tables -------------------------*
do "$code\01.Tables.do"

*--------------- II. Figures -------------------------*
do "$code\03.programs.do"

do "$code\02.Figures.do"

