# Replication Package for "Integrate To Not Surrender: Roads, Trade and Urbanization in Brazil"
Replication package for the EC331 quantitative thesis "Integrate To Not Surrender: Roads, Trade and Urbanization in Brazil". All code and data live under `replication/`, split into five numbered folders that run in order: raw data → cleaning → final datasets → analysis → tables and figures.

Software: Stata 18 (`reghdfe`, `ivreghdfe`, `ppmlhdfe`, `csdid`, `did_imputation`, `estout`) and R (`sidrar`, `data.table`, `dplyr`, `tidyr`, `readr`, `stringr`, `purrr`, `haven`; `sf`, `sp`, `raster`, `ggrepel` for the GIS scripts). `PanelCombine.do` is downloaded at run time by `01.Tables.do`, so the table step needs an internet connection.

Before running, set `global root` at the top of [master_cleaning.do](./replication/02.%20Cleaning/master_cleaning.do) and [master_analysis.do](./replication/04.%20Analysis/master_analysis.do), and the `setwd()` path in [04.tabpost.R](./replication/04.%20Analysis/04.tabpost.R), to your local `replication/` folder.

# Build
### Data pulls (R, requires internet)
Run once before the Stata cleaning. Both scripts cache their downloads and can be re-run safely.

`/replication/02. Cleaning/`:
1. [00.pam_pull.R](./replication/02.%20Cleaning/00.pam_pull.R): Pulls municipality-level harvested area, production quantity and production value from IBGE SIDRA (PAM tables 1612 and 1613; PPM table 3939 for cattle), 1974-2010. Produces `01. Raw Data/pam/pam_temporary.csv`, `pam_permanent.csv` and `ppm_cattle.csv`.
2. [01b.faostat_pull.R](./replication/02.%20Cleaning/01b.faostat_pull.R): Downloads FAOSTAT bulk production and trade files and builds Brazil's crop-level export-orientation ratio EX_g. Produces `01. Raw Data/faostat/ex_ratio.csv`.

### Travel time (R, GIS)
- [fmm.R](./replication/02.%20Cleaning/fmm.R): Computes travel time from each micro- and meso-region to the nearest port with the fast marching method on the 1960-2010 highway rasters and the 1973 national transportation plan (PNV). Produces `fmm_amc_micro.csv` and `fmm_amc_meso.csv` (stored in `01. Raw Data/`). The GIS inputs are not included in this repository.

### Cleaning (Stata)
Execute [master_cleaning.do](./replication/02.%20Cleaning/master_cleaning.do), which runs the following in order. Every script except the last writes only to `02. Cleaning/temp/`.

`/replication/02. Cleaning/`:
1. `amc/_Crosswalk_pre.do` and `amc/_Crosswalk_main.do`: Build minimum comparable areas (AMC) for 1970-2010 following Ehrl (2017).
2. `01.mapping.do`: Maps 2010 municipalities to AMCs, micro-regions and meso-regions. Produces `mapping.dta`.
3. `02.employment.do`: Agricultural employment and urban/rural economically active population.
4. `03.gdp_pop.do`: GDP, population and urban population.
5. `04.controls.do`: Geographic characteristics, distance to waterway and distance to state capital.
6. `05.traveltime.do`: Imports the fast-marching travel times and corrects known algorithm errors.
7. `06.landshare.do`: Builds agricultural land shares by product from the PAM/PPM pulls. Produces `landshare_micro.dta` (micro-region × year × product).
8. `07.classify.R` (run in R, outside Stata): Classifies crops as traded if EX_g ≥ 0.05, then splits traded crops by value per ton into transport-cost-sensitive (< 1,000 R$/ton) and insensitive (> 2,000 R$/ton). Produces `products.dta`. Stops with an error if any crop crosses a threshold.
9. `08.categories.do`: Aggregates products into the categories used in the paper (sensitive, insensitive, processed, pasture, domestic) and builds the crop × micro-region panel.
10. `09.aggregation.do`: The only script that writes to `03. Final Datasets/`.

The `03. Final Datasets/` folder holds the three analysis datasets, one per unit of analysis:
* `micro.dta`: 531 consistent micro-regions, wide by year. Main dataset.
* `meso.dta`: 132 meso-regions. Used in the alternative-samples table.
* `croppanel.dta`: traded crop × micro-region. Used in the pooled transport-sensitivity table.

`products.dta` stores the crop classification.


# Analysis

## Producing figures and tables
To generate the figures and tables, execute [master_analysis.do](./replication/04.%20Analysis/master_analysis.do), then run [04.tabpost.R](./replication/04.%20Analysis/04.tabpost.R) in R. All outputs are written to `05. Tables and Figures/`, and file names match those in the Overleaf `figures/` and `tables/` folders.

Numbering below follows the paper.

`/replication/04. Analysis/`:
- [01.Tables.do](./replication/04.%20Analysis/01.Tables.do): Produces the main tables. Panels A/B/C add state fixed effects and then geographic controls to a baseline that controls only for the initial value of the outcome.
  - `tab_descriptives.tex` (Table 1): Log outcomes on log travel time to port.
  - `tab_aggregate.tex` (Table 2): Long differences on GDP, population, urban population and urban employment share, 1970-2010 (OLS and IV).
  - `tab_landuse.tex` (Table 3): Long differences on total cropland, sensitive, insensitive and pasture land use, 1974-2010.
  - `tab_extensive.tex` (Table 4): Extensive margin of sensitive and insensitive land use (LPM and probit).
  - `tab_pooledtau.tex` (Table 5): Pooled transport-sensitivity interaction on traded crops, from `croppanel.dta`.
  - `tab_heterogeneity.tex` (Table 6): Interactions with distance to waterway, the Center-West region and distance to state capital.
  - `tab_ppml.tex` (Table 7): PPML and reduced-form estimates for land use.
  - `tab_altmeasures.tex` (Table 8): Alternative measures of employment and agricultural output.
  - `tab_altsamples.tex` (Table 9): Micro-regions, micro-regions excluding the Amazon, and meso-regions.
  - `tab_classification.tex` (Appendix Table A1): Product classification.
- [03.programs.do](./replication/04.%20Analysis/03.programs.do): Defines the event-study programs used by `02.Figures.do`.
- [02.Figures.do](./replication/04.%20Analysis/02.Figures.do): Produces the event-study figures and their coefficient tables.
  - `gdp.png`, `pop.png`, `urbpop.png`, `urbshare.png` (Fig 2): Time-varying effects on income and population. Coefficients in `appendix/table1.tex`.
  - `sensitive.png`, `insensitive.png`, `pasture.png` (Fig 3): Time-varying effects on agricultural land use. Coefficients in `appendix/table2.tex`.
  - `road_twfe.png`, `road_imputation.png`, `road_csdid.png` (Fig 4): Time-varying effects on travel time (TWFE, Borusyak et al. 2022, Callaway and Sant'Anna 2021).
  - `appendix/{urbpop,urbshare,pop}_{imputation,csdid}.png` (Appendix Figs 3-5): Robustness of the event studies to alternative estimators.
  - `appendix/{urbpop,urbshare,pop}_treatment_intensity_{1970,...,2010}.png` (Appendix Figs 6-8): Treatment intensity maps.
- [04.tabpost.R](./replication/04.%20Analysis/04.tabpost.R): Rewrites the raw `tab_*.tex` files into paper-ready LaTeX: removes stray `\end{table}` lines left by `panelcombine`, adds `\resizebox` to wide tables, drops the rule above each Observations row, restores the first panel title, and appends the notes. Run after `01.Tables.do`.
- [road_expansion.R](./replication/04.%20Analysis/road_expansion.R): Plots the federal highway network by decade. Produces `appendix/roads/roads{1960,...,2010}.png` (Appendix Fig 1). Requires GIS shapefiles not included in this repository.

Figures produced outside this pipeline:
- `PNV1973.png` (Fig 1): Map of the 1973 national transportation plan.
- `appendix/fmm/fmm_1970.png`, `appendix/fmm/highway_{1960,1980,...,2010}.png` (Appendix Fig 2): Fast-marching travel-time maps, exported from GIS.

### Supplementary tests (not called by `master_analysis.do`)
- [07.prop4_tests.do](./replication/04.%20Analysis/07.prop4_tests.do): Event studies of sensitive export crops by decade, and two tests of complementarity between internal and external integration around the 1988-1991 trade liberalization. Results are displayed only.
- [11.price_frontier.do](./replication/04.%20Analysis/11.price_frontier.do): Estimates transport sensitivity and the trade frontier from farmgate prices (PAM unit values).
- [ta2.do](./replication/04.%20Analysis/ta2.do): Estimates transport sensitivity from farmgate prices on the final 8-crop classification.

Scripts in `02. Cleaning/archive/` and `04. Analysis/archive/` are superseded and kept for reference only.
