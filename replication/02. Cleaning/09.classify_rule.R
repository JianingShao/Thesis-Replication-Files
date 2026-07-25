# =============================================================================
# 09.classify_rule.R
#
# PURPOSE:  Define the product classification used in the specialization
#           analysis (category_ex5), backed by two measured criteria:
#             (a) FAOSTAT export-orientation ratio EX_g (01b.faostat_pull.R):
#                 the Cosar-Fajgelbaum proxy for comparative advantage. A crop
#                 is TRADED if EX_g >= 0.05 (plus sisal and castor, which
#                 Brazil exports heavily but whose FAOSTAT export items do not
#                 match: sisal has production only, castor exports as oil).
#             (b) value per ton from PAM (production value / quantity): the
#                 transport-sensitivity (tau) proxy. Among traded crops, value
#                 per ton splits bulk field/fiber crops (<~2000 R$/ton) from
#                 durable high-value perennials (>~2700 R$/ton).
#
#           Final groups:
#             exp_sensitive   traded bulk field/oilseed/fiber crops shipped raw
#                             or ginned (soy, peanut, castor, cotton, sisal):
#                             low value per ton, high transport sensitivity
#             exp_insensitive traded durable high-value perennial/tree/cured
#                             crops (coffee, cocoa, tobacco, pepper, cashew,
#                             walnut): high value per ton, low sensitivity
#             exp_processed   sugarcane, orange: raw product priced at the
#                             mill/juice plant, not the port, so location
#                             follows processing capacity; excluded from the
#                             specialization test but kept in the denominator
#             pasture         cattle pasture equivalent (benchmark)
#             domestic        everything else (EX_g < 0.05), including domestic
#                             grains, staples, and all fruit and vegetables;
#                             kept in the land denominator as a placebo
#
#           The group assignment is an explicit, documented list; EX_g and
#           value per ton are printed as the justification for each traded
#           crop's placement.
#
# INPUT:    ../01. Raw Data/faostat/ex_ratio.csv     (EX_g)
#           ../02. Cleaning/temp/landshare_micro.dta (value per ton)
#           ../01. Raw Data/freight/product_class.csv (product, shelf_life)
# OUTPUT:   ../01. Raw Data/freight/product_class.csv (product, shelf_life_days,
#                                                       category_ex5)
# =============================================================================

suppressMessages({library(haven); library(dplyr); library(readr)})
setwd("C:/Users/JianingShao/Documents/GitHub/thesis-issue3/replication")

# --- Final group definitions -------------------------------------------------
sensitive <- c("Soja (em grão)", "Amendoim (em casca)", "Mamona (baga)",
               "Algodão herbáceo (em caroço)", "Algodão arbóreo (em caroço)",
               "Sisal ou agave (fibra)")
insensitive <- c("Café (em grão) Total", "Cacau (em amêndoa)",
                 "Fumo (em folha)", "Pimenta-do-reino",
                 "Castanha de caju", "Noz (fruto seco)")
processed <- c("Cana-de-açúcar", "Laranja")

cl <- read_csv("01. Raw Data/freight/product_class.csv", show_col_types = FALSE)

cl <- cl %>% mutate(category_ex5 = case_when(
  grepl("^Pastagem", product) ~ "pasture",
  product %in% sensitive      ~ "exp_sensitive",
  product %in% insensitive    ~ "exp_insensitive",
  product %in% processed      ~ "exp_processed",
  TRUE                        ~ "domestic"))

# Keep only the product, perishability reference, and final category
cl_out <- cl %>% select(product, shelf_life_days, category_ex5)
write_csv(cl_out, "01. Raw Data/freight/product_class.csv")

# --- Justification: EX_g and value per ton for the traded crops --------------
ex <- read_csv("01. Raw Data/faostat/ex_ratio.csv", show_col_types = FALSE) %>%
  select(product, ex_mean)
vpt <- read_dta("02. Cleaning/temp/landshare_micro.dta") %>%
  filter(year == 2010) %>%
  group_by(product) %>%
  summarise(vpt = 1000 * sum(value_prod, na.rm = TRUE) /
                  sum(quantity, na.rm = TRUE), .groups = "drop")

just <- cl %>%
  filter(category_ex5 %in% c("exp_sensitive", "exp_insensitive", "exp_processed")) %>%
  left_join(ex, by = "product") %>%
  left_join(vpt, by = "product") %>%
  mutate(ex_mean = round(ifelse(is.na(ex_mean), 0, ex_mean), 3),
         vpt = round(vpt)) %>%
  arrange(category_ex5, desc(ex_mean)) %>%
  select(product, ex_g = ex_mean, vpt, category_ex5)

cat("=== traded-crop placement, with defining evidence ===\n")
print(as.data.frame(just), right = FALSE)
cat("\n=== group counts ===\n")
print(table(cl$category_ex5))
