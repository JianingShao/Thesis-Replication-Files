# =============================================================================
# 04.tabpost.R
#
# PURPOSE:  Turn the raw esttab / panelcombine output into paper-ready LaTeX.
#           Run AFTER 01.Tables.do.
#
#           Three jobs:
#             1. Remove the stray \end{table} that panelcombine leaves inside
#                the tabular, one per extra panel. Left in place these are a
#                fatal compile error ("Missing } inserted").
#             2. Wrap the table in \begingroup + \arraystretch, and in
#                \resizebox for the wide ones, so columns do not overrun the
#                text block.
#             3. Remove the horizontal rule directly above every
#                Observations row, including one per panel in the
#                multi-panel tables.
#             4. Restore the first panel's title, which panelcombine
#                drops, for the multi-panel tables.
#             5. Append the Notes block, set to the width of the table.
#
#           These steps were previously done by hand on each table and were
#           lost whenever a table was regenerated.
#
# INPUT:    ../05. Tables and Figures/tab_*.tex   (raw, from 01.Tables.do)
# OUTPUT:   the same files, rewritten in place
# =============================================================================

setwd("C:/Users/JianingShao/Documents/GitHub/thesis-issue3/replication")
DIR <- "05. Tables and Figures"

STD <- paste(
  "Each observation is a micro-region. Log change in travel time on roads is",
  "instrumented by the change in travel times on the predicted road network.",
  "The predicted road network is created by geo-referencing the PNV National",
  "Transportation Plan in 1973. The Kleibergen-Paap F-statistic (First-stage F",
  "stat) for weak identification is reported for IV estimates. Standard errors",
  "clustered at the state level are reported in parentheses.")

PANEL_A_BASE <- "Baseline controlling only for the initial value of the outcome"

STARS <- "***,**,* imply significance at the 1\\%, 5\\%, and 10\\% levels, respectively."

spec <- list(
  tab_descriptives = list(resize = TRUE, notes = paste(
    "Each observation is a micro-region. Log travel time is the travel time to",
    "the closest international port on the 1970 road network. Economic outcomes",
    "are measured in 1970; the crop columns are harvested area from the 1974",
    "Municipal Agricultural Production survey, and cattle is the herd converted",
    "at one head per hectare. Standard errors clustered at the state level are",
    "reported in parentheses.", STARS)),

  tab_aggregate = list(panelA = PANEL_A_BASE, resize = TRUE, notes = paste(STD, STARS)),

  tab_landuse = list(panelA = PANEL_A_BASE, resize = TRUE, notes = paste(STD,
    "Outcomes are the log change in category land area, with micro-regions",
    "recording no area assigned a minimum value of one. Total cropland excludes",
    "pasture, which is the cattle herd converted at one head per hectare.", STARS)),

  tab_extensive = list(resize = FALSE, notes = paste(
    "Each observation is a micro-region. Log change in travel time on roads is",
    "instrumented by the change in travel times on the predicted road network.",
    "The predicted road network is created by geo-referencing the PNV National",
    "Transportation Plan in 1973. Dependent variables are defined as a dummy",
    "equal to 1 if the micro-region recorded no area in the category in 1974 but",
    "positive area in 2010. The reported coefficients for Probit Regressions are",
    "the directly interpretable marginal effect.", STARS)),

  tab_pooledtau = list(resize = FALSE, notes = paste(
    "Each observation is a traded crop in a micro-region, over the long",
    "difference 1974-2010. The interaction of transport-cost sensitivity with the",
    "change in log travel time is instrumented by its interaction with the",
    "PIN-induced reduction. Binary $\\tau$ contrasts the transport-cost-sensitive",
    "and insensitive categories; log value per tonne is the national unit value",
    "in 2010. Standard errors clustered at the micro-region level are reported in",
    "parentheses.", STARS)),

  tab_heterogeneity = list(panelA = "Distance to Waterway", resize = TRUE, notes = paste(STD, STARS)),

  tab_ppml = list(resize = TRUE, notes = paste(
    "Each observation is a micro-region. Columns labelled PPML use the actual",
    "change in log travel time; columns labelled Reduced Form replace it with the",
    "PIN-induced reduction. The initial level of the outcome enters as an offset,",
    "so the dependent variable is a growth ratio. Standard errors clustered at the",
    "state level are reported in parentheses.", STARS)),

  tab_altmeasures = list(panelA = PANEL_A_BASE, resize = TRUE, notes = paste(STD,
    "Employment is the economically active population. The crop columns measure",
    "production rather than harvested area; IBGE reports no output quantity for",
    "cattle, so the pasture column measures the herd and is identical to its",
    "counterpart in the land-use table.", STARS)),

  tab_altsamples = list(panelA = "Micro-regions", resize = TRUE, notes = paste(STD,
    "Panel B drops micro-regions in the Legal Amazon. Panel C aggregates to",
    "meso-regions.", STARS)),

  tab_classification = list(resize = FALSE, notes = paste(
    "Value per tonne is national production value divided by quantity in 2010,",
    "from the Municipal Agricultural Production survey. The export ratio is the",
    "FAOSTAT mean ratio of exports to production; it is omitted for sisal and",
    "castor because their FAOSTAT export items do not match the production",
    "series. The final column is the share of micro-regions recording positive",
    "area in 1974."))
)

notes_block <- function(txt) c(
  "\\begin{minipage}{\\wd\\tabbox}",
  "    \\vspace{0.1cm}",
  paste0("    {\\footnotesize \\sloppy \\textit{Notes: } ", txt, "}"),
  "\\end{minipage}")

for (stem in names(spec)) {
  f <- file.path(DIR, paste0(stem, ".tex"))
  if (!file.exists(f)) { cat("skip (absent):", stem, "\n"); next }
  L <- readLines(f, warn = FALSE)

  # idempotent: if already processed, leave the file alone
  if (any(grepl("begingroup", L, fixed = TRUE))) {
    cat(sprintf("%-20s already processed, skipped\n", stem)); next
  }

  # 1. drop every \end{table} except the last
  ends <- grep("^\\s*\\\\end\\{table\\}\\s*$", L)
  stray <- 0
  if (length(ends) > 1) {
    stray <- length(ends) - 1
    L <- L[-ends[-length(ends)]]
  }

  # 1b. drop the rule directly above every Observations row. esttab emits a
  #     \hline before each panel's stats block; multi-panel tables carry one
  #     per panel, and all of them are removed.
  obs   <- grep("^\\s*Observations", L)
  rules <- obs - 1
  rules <- rules[rules >= 1 & grepl("^\\s*\\\\(hline|midrule)\\s*$", L[rules])]
  nrule <- length(rules)
  if (nrule) L <- L[-rules]

  # 1c. panelcombine silently drops the FIRST panel's title, so restore it from
  #     the spec. The row goes directly under the header rule, without the
  #     \linebreak that panels B and C carry: those follow a stats block and
  #     need the extra space, panel A does not.
  pa <- spec[[stem]]$panelA
  if (!is.null(pa)) {
    tabline <- grep("\\\\begin\\{tabular\\}", L, value = TRUE)[1]
    ncol <- sub(".*\\\\begin\\{tabular\\}\\{l\\*\\{([0-9]+)\\}\\{c\\}\\}.*", "\\1", tabline)
    first <- grep("^\\s*\\$\\\\Delta", L)[1]
    if (!is.na(first) && ncol != tabline) {
      L <- append(L,
                  sprintf("\\multicolumn{%s}{l}{\\textbf{\\textit{Panel A: %s}}} \\\\",
                          ncol, pa),
                  after = first - 1)
    }
  }

  # 1d. exhibits sit after the references, one per page, so they go on float
  #     pages: article.cls centres a lone float there. tab_classification stays
  #     inline beside its discussion in the appendix.
  if (!identical(stem, "tab_classification")) {
    L <- sub("^\\s*\\\\begin\\{table\\}\\[htbp\\]",
             "\\\\begin{table}[p]", L)
  }

  # 2. arraystretch group, opened after the \def\sym line where there is one;
  #    hand-written tables have none, so fall back to \begin{table}
  i <- grep("\\\\def\\\\sym", L)[1]
  if (is.na(i)) i <- grep("^\\s*\\\\begin\\{table\\}", L)[1]
  L <- append(L, c("\\begingroup", "\\renewcommand{\\arraystretch}{1.3}"), after = i)

  # 3. optional resizebox around the tabular
  if (spec[[stem]]$resize) {
    b <- grep("^\\s*\\\\begin\\{tabular\\}", L)[1]
    L <- append(L, "\\resizebox{\\linewidth}{!}{", after = b - 1)
    e <- tail(grep("^\\s*\\\\end\\{tabular\\}", L), 1)
    L[e] <- paste0(L[e], "}")
  }

  # 3b. wrap the table body in a savebox: the notes minipage is then set to
  #     \wd\tabbox so it is exactly as wide as the table. \tabbox is declared
  #     once in the paper preamble.
  b <- grep("^\\s*\\\\(resizebox|begin\\{tabular\\})", L)[1]
  L <- append(L, "\\sbox{\\tabbox}{%", after = b - 1)
  e <- tail(grep("^\\s*\\\\end\\{tabular\\}", L), 1)
  L <- append(L, c("}", "\\usebox{\\tabbox}"), after = e)

  # 4. add the notes, then close the group AFTER them: \setbox is local, so an
  #    earlier \endgroup would discard the box and \wd\tabbox would be 0pt.
  e <- tail(grep("^\\s*\\\\end\\{table\\}\\s*$", L), 1)
  L <- append(L, c(notes_block(spec[[stem]]$notes), "\\endgroup"), after = e - 1)

  writeLines(L, f)
  cat(sprintf("%-20s stray end{table}: %d   obs-rules: %d   resizebox: %-5s notes: yes\n",
              stem, stray, nrule, spec[[stem]]$resize))
}
