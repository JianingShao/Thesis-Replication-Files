
version 11.2
clear all
set mem 300m

** step 1: define the path for the working directory where all files (including the original spreadsheet IBGE_1872_2010_original.xml) are located
** all results will also be saved into this directory
cd "..."

** step 2: data preperation
// independent of chosen period
do "_Crosswalk_pre.do"

** step 3: main procedure
// the first argument defines the startyear
// the second argument defines the endyear
// for example:
do "_Crosswalk_main.do" 1872 2010
