# =============================================================================
# 07.classify.R
#
# PURPOSE:  Define the product classification used in the specialization
#           analysis, backed by two measured criteria:
#             (a) FAOSTAT export-orientation ratio EX_g (01b.faostat_pull.R):
#                 the Cosar-Fajgelbaum proxy for comparative advantage. A crop
#                 is TRADED if EX_g >= 0.05 (plus sisal and castor, which
#                 Brazil exports heavily but whose FAOSTAT export items do not
#                 match: sisal has production only, castor exports as oil).
#             (b) value per ton from PAM (production value / quantity): the
#                 transport-sensitivity (tau) proxy.
#
#           SETTLED RULE (gap rule on value per ton, among traded crops):
#             exp_sensitive    < 1,000 R$/ton   soy 543, sisal 897, castor 951
#             exp_insensitive  > 2,000 R$/ton   walnut 2694, coffee 3980,
#                                               pepper 5155, cocoa 5223,
#                                               tobacco 5734
#             the 1,000-2,000 band is EXCLUDED as ambiguous: cashew 1084,
#             peanut 1094, cotton herbaceo 1400.
#
#           Two documented departures from the mechanical rule:
#             1. Cotton arboreo (869) sits below the band but is excluded as
#                the same crop as cotton herbaceo (1400), which does not.
#                Splitting one crop across groups by variety is not defensible.
#             2. Cashew is separately unusable: zero PAM area in 1974, a
#                collection gap rather than a true absence, so it cannot enter
#                a 1974-2010 long difference.
#           Excluded traded crops go to exp_processed, which stays in the land
#           denominator but out of the specialization test.
#
#           Final groups:
#             exp_sensitive   3 crops, low value per ton, high tau
#             exp_insensitive 5 crops, high value per ton, low tau
#             exp_processed   sugarcane and orange (priced at the mill/juice
#                             plant, not the port) plus the four crops excluded
#                             by the gap rule above
#             pasture         cattle pasture equivalent (benchmark)
#             domestic        everything else (EX_g < 0.05): domestic grains,
#                             staples, fruit and vegetables; kept in the land
#                             denominator as a placebo
#
#           The assignment is an explicit list. The gap rule is then VERIFIED
#           against measured value per ton, and the script stops if any crop
#           has landed on the wrong side of a threshold.
#
# INPUT:    ../01. Raw Data/freight/product_shelf_life.csv   (hand-curated)
#           ../01. Raw Data/faostat/ex_ratio.csv             (EX_g)
#           ../02. Cleaning/temp/landshare_micro.dta         (value per ton)
# OUTPUT:   ../02. Cleaning/temp/products.dta
#             product, shelf_life_days, category_ex5, ex_g, vpt, lnvpt
#
# NOTE ON FILE LAYOUT. This script used to read and overwrite
#       01. Raw Data/freight/product_class.csv, which mixed a hand-curated
#       column (shelf life) with a derived one (category) in a single file
#       under Raw Data. The curated half now lives in product_shelf_life.csv
#       and is never written to; everything derived goes to temp/products.dta.
#
# ORDER:  must run AFTER 06.landshare.do and BEFORE 08.categories.do.
# =============================================================================

suppressMessages({library(haven); library(dplyr); library(readr)})
setwd("C:/Users/JianingShao/Documents/GitHub/thesis-issue3/replication")

# --- Settled group definitions -----------------------------------------------
sensitive <- c("Soja (em grão)", "Mamona (baga)", "Sisal ou agave (fibra)")

insensitive <- c("Café (em grão) Total", "Cacau (em amêndoa)",
                 "Fumo (em folha)", "Pimenta-do-reino", "Noz (fruto seco)")

# Sugarcane and orange are processed at origin; the remaining four are traded
# crops excluded by the gap rule (see header).
processed <- c("Cana-de-açúcar", "Laranja",
               "Castanha de caju", "Amendoim (em casca)",
               "Algodão herbáceo (em caroço)", "Algodão arbóreo (em caroço)")

cl <- read_csv("01. Raw Data/freight/product_shelf_life.csv",
               show_col_types = FALSE)

cl <- cl %>% mutate(category_ex5 = case_when(
  grepl("^Pastagem", product) ~ "pasture",
  product %in% sensitive      ~ "exp_sensitive",
  product %in% insensitive    ~ "exp_insensitive",
  product %in% processed      ~ "exp_processed",
  TRUE                        ~ "domestic"))

# --- Guard: every named crop must exist in the product list ------------------
named <- c(sensitive, insensitive, processed)
missing_named <- setdiff(named, cl$product)
if (length(missing_named) > 0) {
  stop("product names not found in product_shelf_life.csv (encoding?): ",
       paste(missing_named, collapse = " | "))
}

# --- Attach EX_g and value per ton -------------------------------------------
ex <- read_csv("01. Raw Data/faostat/ex_ratio.csv", show_col_types = FALSE) %>%
  select(product, ex_mean)
vpt <- read_dta("02. Cleaning/temp/landshare_micro.dta") %>%
  filter(year == 2010) %>%
  group_by(product) %>%
  summarise(vpt = 1000 * sum(value_prod, na.rm = TRUE) /
                  sum(quantity, na.rm = TRUE), .groups = "drop")

out <- cl %>%
  left_join(ex,  by = "product") %>%
  left_join(vpt, by = "product") %>%
  rename(ex_g = ex_mean) %>%
  mutate(ex_g = ifelse(is.na(ex_g), 0, ex_g),
         lnvpt = ifelse(is.finite(vpt) & vpt > 0, log(vpt), NA_real_))

write_dta(out %>% select(product, shelf_life_days, category_ex5,
                         ex_g, vpt, lnvpt),
          "02. Cleaning/temp/products.dta")

# --- Report -------------------------------------------------------------------
just <- out %>%
  filter(category_ex5 %in% c("exp_sensitive", "exp_insensitive", "exp_processed")) %>%
  mutate(ex_g = round(ex_g, 3), vpt = round(vpt)) %>%
  arrange(category_ex5, vpt) %>%
  select(product, ex_g, vpt, category_ex5)

cat("=== traded-crop placement, with defining evidence ===\n")
print(as.data.frame(just), right = FALSE)
cat("\n=== group counts ===\n")
print(table(out$category_ex5))

# --- Verify the gap rule against measured value per ton ----------------------
chk <- just %>% filter(category_ex5 %in% c("exp_sensitive", "exp_insensitive"))
bad_s <- chk %>% filter(category_ex5 == "exp_sensitive",   vpt >= 1000)
bad_i <- chk %>% filter(category_ex5 == "exp_insensitive", vpt <= 2000)

cat("\n=== gap-rule verification (sensitive < 1000 < 2000 < insensitive) ===\n")
if (nrow(bad_s) + nrow(bad_i) > 0) {
  print(as.data.frame(bind_rows(bad_s, bad_i)), right = FALSE)
  stop("gap rule violated: a crop is on the wrong side of its threshold.")
}
cat(sprintf("  OK. sensitive max = %d, insensitive min = %d, n = %d + %d\n",
            max(chk$vpt[chk$category_ex5 == "exp_sensitive"]),
            min(chk$vpt[chk$category_ex5 == "exp_insensitive"]),
            sum(chk$category_ex5 == "exp_sensitive"),
            sum(chk$category_ex5 == "exp_insensitive")))

expect <- c(exp_sensitive = 3, exp_insensitive = 5, exp_processed = 6, pasture = 1)
got <- table(out$category_ex5)
for (g in names(expect)) {
  n <- ifelse(g %in% names(got), got[[g]], 0)
  if (n != expect[[g]]) stop(sprintf("%s has %d products, expected %d", g, n, expect[[g]]))
}
cat("  Settled counts confirmed: 3 sensitive / 5 insensitive / 6 processed / 1 pasture.\n")
cat("  Written: 02. Cleaning/temp/products.dta\n")
