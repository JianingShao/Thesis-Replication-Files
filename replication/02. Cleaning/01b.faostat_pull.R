# =============================================================================
# 01b.faostat_pull.R
#
# PURPOSE:  Pull Brazil's crop-level production and export quantities from
#           FAOSTAT (1970-2010) and construct the export-orientation ratio
#             EX_g = export quantity (raw equivalent) / production quantity
#           averaged over the sample window. EX_g is the measured criterion
#           for classifying goods as traded vs domestic (the analog of the
#           national export-output ratio in Cosar and Fajgelbaum 2016).
#
#           Processed-form exports are converted to raw equivalents using
#           the factors in concordance.csv (sugar -> cane 7.7; FCOJ ->
#           oranges 5.5; cotton lint -> seed cotton 2.5; palm oil -> fruit 5).
#
# NOTE:     The FAOSTAT JSON API (and the CRAN package, which wraps it) now
#           requires developer-portal JWT authentication, so this script
#           downloads the openly served bulk files directly (wide format,
#           domains QCL 24 MB and TCL 89 MB). Brazil subsets are cached so
#           re-runs are instant.
#
# INPUT:    ../01. Raw Data/faostat/concordance.csv
# OUTPUT:   ../01. Raw Data/faostat/ex_ratio.csv
#           (caches in ../01. Raw Data/faostat/cache/)
# =============================================================================

packages <- c("data.table", "dplyr", "readr", "tidyr", "stringr")
to_install <- packages[!packages %in% rownames(installed.packages())]
if (length(to_install) > 0) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
}
library(data.table)
library(dplyr)
library(readr)
library(tidyr)
library(stringr)

setwd("C:/Users/JianingShao/Documents/GitHub/thesis-issue3/replication")
fao_dir   <- file.path("01. Raw Data", "faostat")
cache_dir <- file.path(fao_dir, "cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

# --- 1. Bulk pulls, filtered to Brazil ----------------------------------------

options(timeout = 900)
bulk_base <- "https://bulks-faostat.fao.org/production"

get_brazil <- function(zip_name, element_keep, tag) {
  cache_file <- file.path(cache_dir, paste0(tag, "_brazil.rds"))
  if (file.exists(cache_file)) return(readRDS(cache_file))

  zipf <- file.path(cache_dir, zip_name)
  if (!file.exists(zipf)) {
    message("downloading ", zip_name, " (first run only)...")
    download.file(paste0(bulk_base, "/", zip_name), zipf,
                  mode = "wb", quiet = TRUE)
  }
  csvname <- grep("All_Data\\.csv$", unzip(zipf, list = TRUE)$Name,
                  value = TRUE)[1]
  unzip(zipf, files = csvname, exdir = cache_dir, overwrite = TRUE)

  dt <- fread(file.path(cache_dir, csvname), encoding = "Latin-1",
              showProgress = FALSE)
  setnames(dt, tolower(gsub("[^A-Za-z0-9]+", "_", names(dt))))
  ycols <- paste0("y", 1970:2010)
  ycols <- ycols[ycols %in% names(dt)]
  dt <- dt[area == "Brazil" & element_code %in% element_keep,
           c("item_code", "item", ycols), with = FALSE]
  long <- melt(dt, id.vars = c("item_code", "item"),
               variable.name = "year", value.name = "value")
  long[, year := as.integer(sub("^y", "", year))]
  long[, value := as.numeric(value)]
  out <- as_tibble(long)
  saveRDS(out, cache_file)
  out
}

prod_bz <- get_brazil("Production_Crops_Livestock_E_All_Data.zip", 5510, "qcl")
exp_bz  <- get_brazil("Trade_CropsLivestock_E_All_Data.zip",       5910, "tcl")

cat("QCL Brazil rows:", nrow(prod_bz), "| items:", n_distinct(prod_bz$item), "\n")
cat("TCL Brazil rows:", nrow(exp_bz),  "| items:", n_distinct(exp_bz$item),  "\n")

# --- 2. Concordance matching on item names ------------------------------------

conc <- read_csv(file.path(fao_dir, "concordance.csv"), show_col_types = FALSE)

match_conc <- function(data_items, conc_use) {
  items <- distinct(data_items, item_code, item)
  conc %>%
    filter(use != conc_use) %>%      # keep "both" plus the relevant side
    rowwise() %>%
    mutate(hit = list(items %>%       # keep ALL matches, not just the first,
      filter(str_detect(item, regex(fao_regex, ignore_case = TRUE))))) %>%  # so processed export forms are summed
    unnest(hit, keep_empty = TRUE) %>%
    ungroup()
}

map_prod <- match_conc(prod_bz, conc_use = "exp")
map_exp  <- match_conc(exp_bz,  conc_use = "prod")

cat("--- unmatched production rows ---\n")
print(map_prod %>% filter(is.na(item_code)) %>% pull(product))
cat("--- unmatched export rows ---\n")
print(map_exp %>% filter(is.na(item_code)) %>% pull(product))

# --- 3. Aggregate to PAM products and compute EX_g ----------------------------

prod_g <- map_prod %>% filter(!is.na(item_code)) %>%
  select(product, item_code) %>%
  inner_join(prod_bz, by = "item_code") %>%
  group_by(product, year) %>%
  summarise(prod_qty = sum(value, na.rm = TRUE), .groups = "drop")

exp_g <- map_exp %>% filter(!is.na(item_code)) %>%
  select(product, item_code, factor) %>%
  inner_join(exp_bz, by = "item_code") %>%
  group_by(product, year) %>%
  summarise(exp_qty_raw = sum(value * factor, na.rm = TRUE), .groups = "drop")

ex <- prod_g %>%
  left_join(exp_g, by = c("product", "year")) %>%
  mutate(exp_qty_raw = replace_na(exp_qty_raw, 0),
         ex_ratio = ifelse(prod_qty > 0, exp_qty_raw / prod_qty, NA)) %>%
  group_by(product) %>%
  summarise(ex_mean = mean(ex_ratio, na.rm = TRUE),
            ex_7089 = mean(ex_ratio[year <= 1989], na.rm = TRUE),
            ex_9010 = mean(ex_ratio[year >= 1990], na.rm = TRUE),
            n_years = sum(!is.na(ex_ratio)), .groups = "drop") %>%
  arrange(desc(ex_mean))

write_csv(ex, file.path(fao_dir, "ex_ratio.csv"), na = "")
cat("--- EX_g (export share of production, raw equivalent) ---\n")
print(as.data.frame(ex %>% mutate(across(starts_with("ex_"), ~round(., 3)))),
      right = FALSE)
