# =============================================================================
# 00.pam_pull.R
#
# PURPOSE:  Pull municipality-level agricultural land area (harvested area),
#           production quantity, and production value for all products from
#           IBGE SIDRA, for the construction of within-agriculture land shares
#           l_g (Proposition: specialization within agriculture).
#
#           Tables pulled:
#             - SIDRA 1612: PAM, temporary crops  (soy, cotton, maize, ...)
#             - SIDRA 1613: PAM, permanent crops  (coffee, oranges, cocoa, ...)
#             - SIDRA 3939: PPM, cattle herd size (no area in PPM; convert to
#                           pasture-equivalent area with a stocking rate, or
#                           use Censo Agropecuario pasture area instead)
#
# NOTES:    1. "Area plantada" (variable 109) exists only from 1988 onward.
#              "Area colhida" (variable 216) is available for the full period,
#              so it is used throughout for a consistent 1974-2010 panel.
#           2. Municipality-level PAM starts in 1974, so 1974 replaces the
#              1973 survey year used elsewhere in the project.
#           3. Production value (variable 215) is in current currency, which
#              changes over time (cruzeiro/real); it is only valid for
#              within-location-year revenue shares, not across years.
#           4. The SIDRA API rejects large queries, so the script loops over
#              state x year cells and caches each response; it can be safely
#              re-run and will resume where it stopped.
#
# INPUT:    IBGE SIDRA API (requires internet)
# OUTPUT:   ../01. Raw Data/pam/pam_temporary.csv
#           ../01. Raw Data/pam/pam_permanent.csv
#           ../01. Raw Data/pam/ppm_cattle.csv
#           (plus per-state cache files in ../01. Raw Data/pam/cache/)
# =============================================================================

# --- 0. Setup ----------------------------------------------------------------

packages <- c("sidrar", "dplyr", "purrr", "readr", "tidyr", "stringr")
to_install <- packages[!packages %in% rownames(installed.packages())]
if (length(to_install) > 0) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
}
library(sidrar)
library(dplyr)
library(purrr)
library(readr)
library(tidyr)
library(stringr)

# Guard against hung connections: abort any request after 180 seconds so a
# dropped socket fails into the retry loop instead of freezing the script
httr::set_config(httr::timeout(180))

# Set the working directory to the replication folder (adjust if needed)
setwd("C:/Users/JianingShao/Documents/GitHub/thesis-issue3/replication")
raw_dir   <- file.path("01. Raw Data", "pam")
cache_dir <- file.path(raw_dir, "cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

# Survey years (PAM municipality data starts in 1974; see NOTES)
years <- c(1974, 1980, 1991, 2000, 2010)

# The 27 federative units (UF codes)
ufs <- c(11, 12, 13, 14, 15, 16, 17,           # North
         21, 22, 23, 24, 25, 26, 27, 28, 29,   # Northeast
         31, 32, 33, 35,                       # Southeast
         41, 42, 43,                           # South
         50, 51, 52, 53)                       # Center-West

# SIDRA variable codes
#   216 = area colhida (ha), 214 = quantidade, 215 = valor da producao
vars_pam <- c(216, 214, 215)

# --- 1. Generic cached puller ------------------------------------------------

pull_cell <- function(table, classific, year, uf, variable, tag) {
  cache_file <- file.path(cache_dir, sprintf("%s_%d_%d.rds", tag, year, uf))
  if (file.exists(cache_file)) return(readRDS(cache_file))

  for (attempt in 1:4) {
    out <- tryCatch(
      get_sidra(x         = table,
                variable  = variable,
                period    = as.character(year),
                geo       = "City",
                geo.filter = list("State" = uf),
                classific = classific,
                category  = list("all"),
                format    = 3),
      error = function(e) e
    )
    if (!inherits(out, "error")) {
      saveRDS(out, cache_file)
      Sys.sleep(0.5)   # be polite to the API
      return(out)
    }
    msg <- conditionMessage(out)
    # Large states (MG, SP, RS) exceed SIDRA's 50,000-value limit when all
    # variables are requested at once; split the request by variable instead
    if (grepl("excedeu o limite", msg) && length(variable) > 1) {
      message(sprintf("  [%s] year %d UF %d over API limit; splitting by variable",
                      tag, year, uf))
      parts <- lapply(variable, function(v)
        pull_cell(table, classific, year, uf, v,
                  sprintf("%s_v%d", tag, v)))
      out <- bind_rows(compact(parts))
      if (nrow(out) > 0) {
        saveRDS(out, cache_file)
        return(out)
      }
      break
    }
    message(sprintf("  [%s] year %d UF %d attempt %d failed: %s",
                    tag, year, uf, attempt, msg))
    Sys.sleep(5 * attempt)
  }
  warning(sprintf("[%s] year %d UF %d failed after 4 attempts; skipped.",
                  tag, year, uf))
  NULL
}

pull_table <- function(table, classific, variable, tag) {
  grid <- expand.grid(year = years, uf = ufs)
  message(sprintf("Pulling SIDRA table %d (%s): %d state-year cells",
                  table, tag, nrow(grid)))
  raw <- pmap(grid, function(year, uf) {
    message(sprintf("  %s: year %d, UF %d", tag, year, uf))
    pull_cell(table, classific, year, uf, variable, tag)
  })
  bind_rows(compact(raw))
}

# Reshape SIDRA output to one row per municipality x year x product,
# with columns for area, quantity, and value
tidy_pam <- function(df, product_col) {
  df %>%
    rename(code7        = `Município (Código)`,
           municipality = `Município`,
           year         = `Ano`,
           variable     = `Variável`,
           product      = all_of(product_col),
           value        = `Valor`) %>%
    mutate(variable = case_when(
      str_detect(variable, "colhida")   ~ "area_ha",
      str_detect(variable, "produzida") ~ "quantity",
      str_detect(variable, "Valor")     ~ "value_prod",
      TRUE                              ~ variable)) %>%
    filter(product != "Total") %>%
    select(code7, municipality, year, product, variable, value) %>%
    pivot_wider(names_from = variable, values_from = value)
}

# --- 2. PAM temporary crops (table 1612, classification c81) ------------------

pam_temp_raw <- pull_table(1612, "c81", vars_pam, "pam1612")
pam_temp <- tidy_pam(pam_temp_raw, "Produto das lavouras temporárias")
write_csv(pam_temp, file.path(raw_dir, "pam_temporary.csv"), na = "")
message(sprintf("Saved pam_temporary.csv: %d rows, %d products",
                nrow(pam_temp), n_distinct(pam_temp$product)))

# --- 3. PAM permanent crops (table 1613, classification c82) ------------------

pam_perm_raw <- pull_table(1613, "c82", vars_pam, "pam1613")
pam_perm <- tidy_pam(pam_perm_raw, "Produto das lavouras permanentes")
write_csv(pam_perm, file.path(raw_dir, "pam_permanent.csv"), na = "")
message(sprintf("Saved pam_permanent.csv: %d rows, %d products",
                nrow(pam_perm), n_distinct(pam_perm$product)))

# --- 4. PPM cattle herd (table 3939, classification c79) ----------------------
# Variable 105 = herd size (head). Category 2670 = bovino (cattle).
# PPM has no area variable; convert head counts to pasture-equivalent
# hectares with an assumed stocking rate when constructing land shares.

ppm_raw <- {
  grid <- expand.grid(year = years, uf = ufs)
  raw <- pmap(grid, function(year, uf) {
    message(sprintf("  ppm3939: year %d, UF %d", year, uf))
    pull_cell(3939, "c79", year, uf, 105, "ppm3939")
  })
  bind_rows(compact(raw))
}
ppm_cattle <- ppm_raw %>%
  rename(code7        = `Município (Código)`,
         municipality = `Município`,
         year         = `Ano`,
         herd_type    = `Tipo de rebanho`,
         head         = `Valor`) %>%
  filter(str_detect(herd_type, regex("^bovino", ignore_case = TRUE))) %>%
  select(code7, municipality, year, herd_type, head)
write_csv(ppm_cattle, file.path(raw_dir, "ppm_cattle.csv"), na = "")
message(sprintf("Saved ppm_cattle.csv: %d rows", nrow(ppm_cattle)))

# --- 5. Merge hint -------------------------------------------------------------
# code7 is the 7-digit IBGE municipality code (6 digits + check digit).
# The existing crosswalk (mapping.dta, key: code2010) uses the same coding as
# the manual SIDRA xls downloads; if mapping.dta stores 6-digit codes, truncate:
#   mutate(code2010 = as.integer(substr(code7, 1, 6)))
# before merging and aggregating to micro-regions.
# =============================================================================
