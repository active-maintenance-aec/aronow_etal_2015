# aronow_etal_2015/maintained/in_text_claims.R
# Output: printed CLAIM lines and a CLAIM SUMMARY line; no files
# Depends on: maintained/output/, ground_truth/published_claims.csv,
#   errata_entries.csv, helpers.R, excheckr
# Description: Every number the article and the online supplementary materials
#   state, printed beside the sentence that states it and in the units and
#   rounding of the page it appears on. Each block quotes the published sentence
#   verbatim and then recomputes its number from the pipeline's own output, so
#   this file and ground_truth/build_ground_truth.R reach the same claimed number
#   by two separate paths. Where they disagree, one of them is wrong.
#
#   Nothing here re-runs an estimator or touches the deposited data. Every value
#   is read out of maintained/output/, which run_all.R has already produced.
#
#   Every block prints a line of the form
#
#       CLAIM <claim_id> = <value> || [verdict] <label>
#
#   scored by excheckr against ground_truth/published_claims.csv and
#   errata_entries.csv. The expectation is derived from those two files, never
#   typed here, except where a call site declares one: expect = "range" on the
#   five power readings, each one cell of an unseeded Monte Carlo grid, and
#   expect = "absent" on the five numbers the deposit carries no field for. A
#   descriptive claim that prints no number scores [shape], and the lines under
#   it print the distribution it describes. The run fails on any MISMATCH,
#   STALE, DRIFT, or MISSING, and on any claim the extraction marks needs_block
#   that no block here prints.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))
library(excheckr)

options(width = 200)

read_out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

# Supporting lines under a claim: the distribution a descriptive claim describes,
# printed for the reader and never scored.
detail <- function(label, value) cat(sprintf("    %-62s %s\n", paste0(label, ":"), value))

heading <- function(text) cat("\n", text, "\n", strrep("-", nchar(text)), "\n", sep = "")

t1 <- read_out("table_1_treatment_ns.csv")
t2 <- read_out("table_2_covariate_balance.csv")
t3 <- read_out("table_3_study_a_prevalence.csv")
t4 <- read_out("table_4_study_a_placebo_i.csv")
t5 <- read_out("table_5_study_a_placebo_ii.csv")
t6 <- read_out("table_6_study_b_prevalence.csv")
t7 <- read_out("table_7_study_b_placebo_i.csv")
t8 <- read_out("table_8_study_b_placebo_ii.csv")
ta1 <- read_out("table_a1_factorial.csv")
ta2 <- read_out("table_a2_rep_study_a_prevalence.csv")
ta3 <- read_out("table_a3_rep_study_a_placebo_i.csv")
ta4 <- read_out("table_a4_rep_study_a_placebo_ii.csv")
ta5 <- read_out("table_a5_rep_study_b_prevalence.csv")
ta6 <- read_out("table_a6_rep_study_b_placebo_i.csv")
ta7 <- read_out("table_a7_rep_study_b_placebo_ii.csv")
ta8 <- read_out("table_a8_rep_factorial.csv")

sizes <- read_out("text_sample_sizes.csv")
main_n <- filter(sizes, experiment == "main")
rep_n <- filter(sizes, experiment == "replication")

power_grid <- read_out("figure_a1_placebo_i_power.csv")
grid_spec <- read_out("text_figure_a1_grid_spec.csv")
fig_1 <- read_out("figure_1_study_a_prevalence.csv")
orig_rep <- read_out("text_original_vs_replication.csv")

# The extraction and the errata spine, every column as character: value_paper
# carries "0.80", and a reader left to guess returns 0.8 and loses the precision
# the comparison depends on.
published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))
errata <- read_csv(here::here("errata_entries.csv"),
                   col_types = cols(.default = col_character()))

# format = "id" prints CLAIM <id> = <value> || [verdict] <label>. The label is the
# extraction's own claim text.
claim_start(published = published, errata = errata, format = "id", label_column = "claim")

stated <- function(id) {
  value <- published$value_paper[published$claim_id == id]
  stopifnot(length(value) == 1)
  value
}

# The power grid is read by admitter count and violation proportion, which are the
# settings the article names, never by the power it claims to find there.
power_of <- function(violation, admitters, proportion) {
  cell <- power_grid |>
    filter(panel == violation, admitter_n == admitters, abs(prop - proportion) < 1e-9)
  stopifnot(nrow(cell) == 1)
  cell$power
}

rejections <- function(tab) sum(tab$p_value < 0.05)
rejecting <- function(tab) str_flatten_comma(tab$item[tab$p_value < 0.05], last = " and ")
cell_of <- function(tab, which_item, column) tab[[column]][tab$item == which_item]

# 4. Placebo Tests ----

heading("4.1 Placebo Test I (pp. 50 to 51)")

# "The placebo test does not always have high power. For example, if 20 percent of
# 200 subjects responding \"Yes\" to the direct question are false confessors, the
# placebo test only has about 30 percent power."
# One cell of a grid the deposit simulated without a seed, so the expectation is a
# range rather than the printed digit.
claim("text, p. 50 :: Power at 200 admitters and 20 percent false confessors (%)",
      100 * power_of("no false confessions", 200, 0.20), expect = "range")

# "But when 20 percent of 800 subjects answering \"Yes\" are falsely confessing, the
# test has approximately 80 percent power."
claim("text, p. 51 :: Power at 800 admitters and 20 percent false confessors (%)",
      100 * power_of("no false confessions", 800, 0.20), expect = "range")

# 5. Application ----

heading("5.1 Experimental Design (pp. 52 to 53)")

# "We recruited a convenience sample of 1,023 subjects from Mechanical Turk."
claim("text, p. 52 :: Subjects recruited for the main experiment", main_n$n_deposited)

# "Two subjects failed this quality check, and we exclude them from the main
# analysis. An additional seven subjects failed to respond to one or more of our
# questions, so we exclude them from the main analysis as well."
claim("text, p. 52 :: Subjects excluded from the main experiment", main_n$n_dropped)

# "The resulting sample size is n = 1,014."
claim("text, p. 52 :: Complete cases in the main experiment", main_n$n_complete)

# "Consistent with our randomization procedure, each cell in the table (with the
# exception of the diagonal) contains approximately one-quarter of the subjects."
# Descriptive. The diagonal the sentence excepts is the two-by-two block each
# randomization forms with itself, where a subject cannot be in both cells, so the
# blocks are dropped by which randomization a condition belongs to rather than by
# the value in the cell. The median share is the claim's value and the
# distribution is printed under it.
randomization_of <- function(x) if_else(str_starts(x, "Study"), "study", str_remove(x, " [TC]$"))

off_block <- t1 |>
  pivot_longer(-condition, names_to = "crossed_with", values_to = "n") |>
  drop_na(n) |>
  filter(randomization_of(condition) != randomization_of(crossed_with)) |>
  mutate(share = 100 * n / main_n$n_complete)

claim("text, p. 53 :: Every off-diagonal crossing holds about a quarter of the subjects",
      median(off_block$share), digits = 1)
detail("Crossings outside the diagonal blocks", nrow(off_block))
detail("Their share of the complete cases, smallest to largest (paper: about 25 percent)",
       sprintf("%.1f to %.1f percent", min(off_block$share), max(off_block$share)))
detail("Quartiles of that share",
       str_flatten_comma(sprintf("%.1f", quantile(off_block$share, c(0.25, 0.5, 0.75)))))

# "Our subject pool is more likely to be white, male, liberal, well educated, and
# young than the general population."
# Descriptive. Only the first half is checkable here: the deposit carries the
# sample and not the general population, so the shares are printed and the
# comparison is left to the reader.
share_of <- function(level_names) sum(t2$`Study A Treat`[t2$level %in% level_names])

claim("text, p. 53 :: The subject pool is disproportionately white, male, liberal, educated and young",
      share_of("White, non Hispanic"), digits = 1)
detail("Study A treatment group, white non-Hispanic", sprintf("%.1f percent", share_of("White, non Hispanic")))
detail("Study A treatment group, male", sprintf("%.1f percent", share_of("Male")))
detail("Study A treatment group, liberal", sprintf("%.1f percent", share_of("Liberal")))
detail("Study A treatment group, some college or more",
       sprintf("%.1f percent", share_of(c("Some College", "4-year College Degree", "Graduate School"))))
detail("Study A treatment group, under 35",
       sprintf("%.1f percent", share_of(c("18 to 24", "25 to 34"))))

heading("5.2 Study A, Direct Questions First (p. 54)")

# "NOTE. n = 500 for all estimates." (note to Table 3)
claim("table_3 note :: Study A sample size", main_n$n_study_a)

# "For example, the direct question estimate Y of the percentage agreeing that
# Muslims should not be allowed to teach in public schools is 11 percent, the list
# experiment estimate is 17 percent, and the combined estimate is 19 percent."
claim("text, p. 54 :: Direct question estimate for Muslim teachers (%)",
      100 * cell_of(t3, "Muslim Teachers", "direct"))
claim("text, p. 54 :: Standard list estimate for Muslim teachers (%)",
      100 * cell_of(t3, "Muslim Teachers", "conv"))
claim("text, p. 54 :: Combined estimate for Muslim teachers (%)",
      100 * cell_of(t3, "Muslim Teachers", "combined"))

# "the reductions in estimated sampling variance are dramatic, ranging from 14 to
# 67 percent."
# The full set is printed as well, so the range can be confirmed by eye rather
# than inferred from two numbers.
claim("text, p. 54 :: Smallest reduction in sampling variance, Study A (%)", min(t3$var_reduc))
claim("text, p. 54 :: Largest reduction in sampling variance, Study A (%)", max(t3$var_reduc))
detail("Study A reductions in sampling variance, all five",
       str_flatten_comma(sprintf("%.0f", sort(t3$var_reduc))))

# "As expected, reductions tend to be larger when a larger number of subjects
# respond \"Yes\" to the direct question."
# Descriptive.
claim("text, p. 54 :: Reductions are larger where more subjects answer Yes",
      cor(t3$direct, t3$var_reduc), digits = 3)
detail("Direct question estimate, ascending",
       str_flatten_comma(sprintf("%.3f", sort(t3$direct))))
detail("Variance reduction in that same order",
       str_flatten_comma(sprintf("%.1f", t3$var_reduc[order(t3$direct)])))

# "the 95 percent confidence intervals around the combined estimate are always
# tighter than those around the standard estimate."
# Descriptive. Read off the plotted intervals rather than the standard errors, so
# that the claim is checked against what the figure actually draws.
interval_widths <- fig_1 |>
  mutate(width = ui - li) |>
  select(item, estimator, width) |>
  pivot_wider(names_from = estimator, values_from = width)

claim("text, p. 54 :: The combined interval is always tighter than the standard list interval",
      sum(interval_widths$`Combined Estimate` < interval_widths$`Standard List Estimate`),
      digits = 0)
detail("Items plotted", nrow(interval_widths))
detail("Ratio of combined to standard list interval width",
       str_flatten_comma(sprintf("%.3f", interval_widths$`Combined Estimate` /
                                   interval_widths$`Standard List Estimate`)))

# "In two cases, we reject the joint null hypothesis of Monotonicity, No Liars, and
# No Design Effects: Public Transportation (p = 0.02) and CNN (p = 0.03)."
claim("text, p. 54 :: Placebo Test I rejections in Study A", rejections(t4), digits = 0)
detail("Items rejecting", rejecting(t4))
claim("text, p. 54 :: Placebo Test I p-value quoted for Public Transportation",
      cell_of(t4, "Public Transportation", "p_value"))
claim("text, p. 54 :: Placebo Test I p-value quoted for CNN", cell_of(t4, "CNN", "p_value"))

# Footnote 1: "The pattern for the other socially sensitive topic, Spanish
# speaking, is reversed: the direct question estimate is greater than both list
# experimental estimates. Our replication study (described below) found the
# opposite pattern, suggesting that this apparent contrast is due to sampling
# variability."
# Descriptive, in two halves. Each value is the direct estimate less the nearer
# list estimate: positive where the direct estimate exceeds both, negative where
# it falls below both.
spanish <- function(tab) {
  c(cell_of(tab, "Spanish-speaking", "direct"), cell_of(tab, "Spanish-speaking", "conv"),
    cell_of(tab, "Spanish-speaking", "combined"))
}

claim("footnote 1, p. 54 :: Spanish speaking runs the other way in the main experiment",
      spanish(t3)[1] - max(spanish(t3)[2:3]), digits = 3)
detail("Spanish speaking, main experiment Study A (direct, standard list, combined)",
       str_flatten_comma(sprintf("%.3f", spanish(t3))))
claim("footnote 1, p. 54 :: Spanish speaking runs the other way again in the replication",
      spanish(ta2)[1] - min(spanish(ta2)[2:3]), digits = 3)
detail("Spanish speaking, replication Study A (direct, standard list, combined)",
       str_flatten_comma(sprintf("%.3f", spanish(ta2))))

heading("5.3 Study B, List Experiments First (pp. 56 to 57)")

# "NOTE. n = 514 for all estimates." (note to Table 6)
claim("table_6 note :: Study B sample size", main_n$n_study_b)

# "The direct question estimates are very similar between Studies A and B, none of
# the differences between the estimates is significant at the 0.05 level."
# Descriptive. Table A1 differences Study A against Study B item by item.
direct_z <- ta1$direct_diff / ta1$direct_se
claim("text, p. 56 :: No direct question estimate differs between the studies",
      sum(2 * pnorm(-abs(direct_z)) < 0.05), digits = 0)
detail("Study A minus Study B direct question z statistics",
       str_flatten_comma(sprintf("%.2f", direct_z)))

# "The combined estimator produces tighter estimates in Study B as well, with
# estimated sampling variability reductions in a very similar range."
# Descriptive. The claim's value is the Study B maximum; both ranges are printed.
claim("text, p. 56 :: Study B sampling variance reductions fall in a similar range",
      max(t6$var_reduc), digits = 1)
detail("Study A reductions", sprintf("%.1f to %.1f percent", min(t3$var_reduc), max(t3$var_reduc)))
detail("Study B reductions", sprintf("%.1f to %.1f percent", min(t6$var_reduc), max(t6$var_reduc)))

# "None of the values of the difference-in-means are statistically significantly
# different from 1 using the placebo test, and a joint test via Fisher's method is
# insignificant as well."
# Descriptive, in two halves. The article prints no value for the joint test, so it
# is reconstructed here from the item level p-values it does print.
claim("text, p. 56 :: No Placebo Test I rejection in Study B", rejections(t7), digits = 0)
detail("Study B Placebo Test I p-values", str_flatten_comma(sprintf("%.3f", t7$p_value)))
fisher_chi <- -2 * sum(log(t7$p_value))
claim("text, p. 56 :: Fisher's method joint test of Placebo Test I in Study B",
      pchisq(fisher_chi, df = 2 * nrow(t7), lower.tail = FALSE), digits = 3)
detail("Fisher's method statistic", sprintf("chi-squared %.2f on %d df", fisher_chi, 2 * nrow(t7)))

# "In two of the five cases, direct questions were significantly affected by the
# treatment list: treated subjects were 8.6 percentage points less likely to
# declare their support for nuclear power and were 13.2 percentage points more
# likely to report watching CNN."
# The article prints magnitudes and states the directions in words, so the value
# is the magnitude and the signed estimate is printed under it.
claim("text, p. 57 :: Placebo Test II rejections in Study B", rejections(t8), digits = 0)
detail("Items rejecting", rejecting(t8))
claim("text, p. 57 :: Effect of the treatment list on the nuclear power direct question, Study B (pp)",
      abs(100 * cell_of(t8, "Nuclear Power", "beta")))
claim("text, p. 57 :: Effect of the treatment list on the CNN direct question, Study B (pp)",
      abs(100 * cell_of(t8, "CNN", "beta")))
detail("Signed effects, nuclear power and CNN (percentage points)",
       str_flatten_comma(sprintf("%.1f", 100 * c(cell_of(t8, "Nuclear Power", "beta"),
                                                 cell_of(t8, "CNN", "beta")))))

heading("5.4 Replication Study (pp. 57 to 58)")

# "We conducted a replication study following the identical design with 506 new
# Mechanical Turk subjects in a replication of Study A and 506 in a replication of
# Study B."
claim("text, p. 57 :: Replication Study A sample size", rep_n$n_study_a)
claim("text, p. 57 :: Replication Study B sample size", rep_n$n_study_b)

# "The list experimental estimates vary somewhat between the original experiments
# and the replication, but none of these differences are significant (p > 0.05)."
# Descriptive. No published table reports this comparison, so it is built by
# differencing each estimate against its counterpart ten months later.
claim("text, p. 58 :: No estimate differs between the original experiment and the replication",
      sum(orig_rep$p_value < 0.05), digits = 0)
detail("Comparisons", nrow(orig_rep))
detail("Smallest p-value across all estimators", sprintf("%.3f", min(orig_rep$p_value)))
detail("Smallest p-value among the standard list estimates",
       sprintf("%.3f", min(orig_rep$p_value[orig_rep$estimator == "conv"])))

# "One of the five placebo tests was significant in Study A, and three of the five
# were significant in Study B."
# Descriptive.
claim("text, p. 58 :: Placebo Test I rejections in the replication of Study A",
      rejections(ta3), digits = 0)
detail("Items rejecting", rejecting(ta3))
claim("text, p. 58 :: Placebo Test I rejections in the replication of Study B",
      rejections(ta6), digits = 0)
detail("Items rejecting", rejecting(ta6))

# "Perhaps surprisingly, the effect of the treatment list on direct answers to the
# CNN question presented in table 8 was also replicated."
# Descriptive. The value is the replication estimate.
claim("text, p. 58 :: The CNN treatment list effect replicates",
      cell_of(ta7, "CNN", "beta"), digits = 3)
detail("CNN Placebo Test II, main experiment Study B",
       sprintf("%.3f (p = %.3f)", cell_of(t8, "CNN", "beta"), cell_of(t8, "CNN", "p_value")))
detail("CNN Placebo Test II, replication Study B",
       sprintf("%.3f (p = %.3f)", cell_of(ta7, "CNN", "beta"), cell_of(ta7, "CNN", "p_value")))

# 6. Discussion ----

heading("6. Discussion (p. 59)")

# "we reject the joint null hypothesis of Monotonicity, No Liars, and No Design
# Effects for two of the experiments in Study A but fail to reject it for any of
# the five experiments in Study B. Our replication study saw the opposite pattern:
# one rejection in Study A, and three rejections in Study B."
# Descriptive, and a restatement of the Results counts. Each value is the
# experiment's total over both studies; the split is printed under it.
claim("discussion, p. 59 :: Placebo Test I rejections restated for Study A",
      rejections(t4) + rejections(t7), digits = 0)
detail("Placebo Test I rejections, main experiment (paper: two in A, none in B)",
       sprintf("Study A %d of 5, Study B %d of 5", rejections(t4), rejections(t7)))
claim("discussion, p. 59 :: Placebo Test I rejections restated for the replication",
      rejections(ta3) + rejections(ta6), digits = 0)
detail("Placebo Test I rejections, replication (paper: one in A, three in B)",
       sprintf("Study A %d of 5, Study B %d of 5", rejections(ta3), rejections(ta6)))

# "Nevertheless, Placebo Test I detected many instances of violated assumptions
# (six of twenty opportunities), suggesting that caution is warranted when
# interpreting list experimental estimates of prevalence."
placebo_i_tables <- list(t4, t7, ta3, ta6)
claim("discussion, p. 59 :: Placebo Test I rejections across all four studies",
      sum(map_int(placebo_i_tables, rejections)))
claim("discussion, p. 59 :: Placebo Test I opportunities across all four studies",
      sum(map_int(placebo_i_tables, nrow)))

# Appendix C. Power of Placebo Test I ----

heading("Appendix C, Power of Placebo Test I")

# "We varied NYes from 100 to 1000 in steps of 50, the proportion of False
# Confessors, Liars, and Design Affected units from 0 to 1 in steps of 0.01, and
# the success probability of the binomial distribution from 0 to 1 in steps of
# 0.01. We conducted 1,000 simulations of each combination."
spec_value <- function(name) grid_spec$value[grid_spec$claim == name]

claim("appendix C text :: Smallest number of admitters on the grid",
      spec_value("Smallest number of admitters"))
claim("appendix C text :: Largest number of admitters on the grid",
      spec_value("Largest number of admitters"))
claim("appendix C text :: Step between admitter counts", spec_value("Step between admitter counts"))
claim("appendix C text :: Step between proportions", spec_value("Step between proportions"))
detail("Proportions on the grid",
       sprintf("%.0f to %.0f", spec_value("Smallest proportion"), spec_value("Largest proportion")))
claim("appendix C text :: Simulations per grid cell", spec_value("Simulations per grid cell"))
claim("appendix C text :: Grid cells per panel of Figure A1", spec_value("Grid cells per panel"))

# "When approximately 20% of a sample of 800 confessors falsely confess, lie on the
# treatment list, or change their responses to the non-sensitive items on the
# treatment list, the placebo test achieves 80% power."
# Each is one cell of the unseeded grid, so each is declared a range. The value one
# decimal finer is printed under each, because two of the three sit within half a
# point of the boundary the appendix rounds at.
power_800 <- function(violation) 100 * power_of(violation, 800, 0.20)

claim("appendix C text :: Power at 800 admitters and 20 percent false confessors (%)",
      power_800("no false confessions"), expect = "range")
claim("appendix C text :: Power at 800 admitters and 20 percent liars (%)",
      power_800("no liars"), expect = "range")
claim("appendix C text :: Power at 800 admitters and 20 percent design affected (%)",
      power_800("no design effects"), expect = "range")
detail("The three at one decimal finer (false confessors, liars, design affected)",
       str_flatten_comma(sprintf("%.1f", map_dbl(c("no false confessions", "no liars",
                                                    "no design effects"), power_800))))

# Appendix E. Factorial Design ----

heading("Appendix E, Factorial Design")

# "The order in which the direct and list questions does not appear to have had a
# significant impact on the Direct or Combined List estimates of prevalence, but
# does appear to have changed the Conventional List estimates in two cases."
# Descriptive. The value counts direct and combined rejections together.
reject_count <- function(diff, se) sum(2 * pnorm(-abs(diff / se)) < 0.05)

claim("appendix E text :: Question order does not move the direct or combined estimates",
      reject_count(ta1$direct_diff, ta1$direct_se) +
        reject_count(ta1$combined_diff, ta1$combined_se),
      digits = 0)
detail("Direct estimates moved by question order (paper: none)",
       sprintf("%d of %d", reject_count(ta1$direct_diff, ta1$direct_se), nrow(ta1)))
detail("Combined estimates moved by question order (paper: none)",
       sprintf("%d of %d", reject_count(ta1$combined_diff, ta1$combined_se), nrow(ta1)))
detail("Conventional list estimates moved by question order (paper: two)",
       sprintf("%d of %d", reject_count(ta1$conv_diff, ta1$conv_se), nrow(ta1)))

# "The list experimental estimate of the proportion supporting Nuclear power is
# 24.9 percentage points higher when the direct questions are asked first, whereas
# the estimate of those watching CNN is 30.7 percentage points lower when the
# direct questions are asked first."
# The CNN direction is stated in words, so its value is the magnitude.
claim("appendix E text :: Order effect on the conventional list estimate for nuclear power (pp)",
      100 * cell_of(ta1, "Nuclear Power", "conv_diff"))
claim("appendix E text :: Order effect on the conventional list estimate for CNN (pp)",
      abs(100 * cell_of(ta1, "CNN", "conv_diff")))
detail("Signed CNN order effect (percentage points)",
       sprintf("%.1f", 100 * cell_of(ta1, "CNN", "conv_diff")))

# Appendix F. Replication Study ----

heading("Appendix F, Replication Study")

# "1019 users started the survey, but 7 either did not complete the survey or
# failed the attention question, leaving 1012 complete cases. 506 subjects
# participated in Study A and 506 participated in Study B."
claim("appendix F text :: Users who started the replication survey", rep_n$n_deposited)
claim("appendix F text :: Excluded from the replication", rep_n$n_dropped)
claim("appendix F text :: Complete cases in the replication", rep_n$n_complete)
claim("appendix F text :: Replication Study A sample size", rep_n$n_study_a)
claim("appendix F text :: Replication Study B sample size", rep_n$n_study_b)

# "In the original study, two of five questions failed the placebo test in Study A
# and none of the question failed in Study B. The replication shows a different
# pattern: one of five fail in Study A, whereas three of five (at the 5% level or
# greater) fail in Study B."
# Descriptive, and the appendix's own restatement of the Discussion counts.
claim("appendix F text :: Placebo Test I rejections restated for the main experiment",
      rejections(t4) + rejections(t7), digits = 0)
detail("Main experiment Placebo Test I (paper: two in A, none in B)",
       sprintf("Study A %d of 5, Study B %d of 5", rejections(t4), rejections(t7)))
claim("appendix F text :: Placebo Test I rejections restated for the replication",
      rejections(ta3) + rejections(ta6), digits = 0)
detail("Replication Placebo Test I (paper: one in A, three in B)",
       sprintf("Study A %d of 5, Study B %d of 5", rejections(ta3), rejections(ta6)))

# "In the original study, both Nuclear Power and CNN failed the second placebo
# test, but in the replication, only CNN fails."
# Descriptive. The value counts rejections across both experiments.
claim("appendix F text :: Placebo Test II rejections in the main experiment and the replication",
      rejections(t8) + rejections(ta7), digits = 0)
detail("Placebo Test II rejections, main experiment Study B (paper: nuclear power and CNN)",
       rejecting(t8))
detail("Placebo Test II rejections, replication Study B (paper: CNN only)", rejecting(ta7))

# "We interpret this result to mean that the effect of the treatment list on direct
# answers to the CNN is not a fluke due to sampling variability but rather a robust
# causal effect on the order of 10 percentage points."
# Descriptive. The value is the average of the two estimates in percentage points.
cnn_effects <- 100 * c(cell_of(t8, "CNN", "beta"), cell_of(ta7, "CNN", "beta"))
claim("appendix F text :: Size of the replicated CNN treatment list effect",
      mean(cnn_effects), digits = 1)
detail("CNN treatment list effect, main experiment and replication (percentage points)",
       str_flatten_comma(sprintf("%.1f", cnn_effects)))

# Design parameters and structural facts ----
# These are the numbers that describe how the study and the simulation were built
# rather than what they found. Each is verified against the source that settles it:
# the estimates the pipeline already wrote, or the script that generates the
# simulation. Where the deposit records nothing at all the claim is declared
# absent at the call site.

heading("Design parameters and structural facts")

figure_a1_source <- read_lines(here::here("maintained", "figure_a1_placebo_i_power.R"))
helpers_source <- read_lines(here::here("maintained", "helpers.R"))

# The one setting a pattern captures in a script's source, asserted unique so a
# second, disagreeing setting cannot hide behind the first.
setting_in <- function(source_lines, pattern) {
  values <- unique(na.omit(str_match(source_lines, pattern)[, -1, drop = FALSE]))
  stopifnot(nrow(values) == 1)
  as.numeric(values[1, ])
}

# "For example, if 20 percent of 200 subjects responding \"Yes\" to the direct
# question are false confessors, the placebo test only has about 30 percent power."
claim("text, p. 50 :: Admitters in the low power example",
      if (200 %in% power_grid$admitter_n) 200 else NA_real_)

# "We conducted five list experiments that paralleled five direct questions. In
# three list experiments, we chose topics that are not socially sensitive:
# preferences over alternative energy sources, neighborhood characteristics, and
# news organizations. Two of the five list experiments dealt with racial and
# religious prejudice."
sensitive_items <- c("Spanish-speaking", "Muslim Teachers")
claim("text, p. 52 :: List experiments conducted", nrow(t3))
claim("text, p. 52 :: List experiments on topics that are not socially sensitive",
      sum(!t3$item %in% sensitive_items))
detail("Items the article calls not socially sensitive",
       str_flatten_comma(t3$item[!t3$item %in% sensitive_items]))
claim("text, p. 52 :: List experiments on racial and religious prejudice",
      sum(t3$item %in% sensitive_items))

# "We offered subjects $1.00 to complete our survey, which is equivalent to a
# $15.45 hourly rate." And, of the replication, "conducted with a new pool of
# Mechanical Turk respondents ten months after the first study."
# The deposited data carry no payment field and no timestamp, so nothing in the
# pipeline can speak to these.
claim("text, p. 52 :: Payment per subject (dollars)", NA_real_, expect = "absent")
claim("text, p. 52 :: Equivalent hourly rate (dollars)", NA_real_, expect = "absent")
claim("appendix F text :: Months between the two experiments", NA_real_, expect = "absent")

# "Two subjects failed this quality check ... An additional seven subjects failed to
# respond to one or more of our questions."
# The deposit records the incomplete responses and nothing that identifies a failed
# attention check, so only the total is recoverable.
claim("text, p. 52 :: Subjects who failed the attention question", NA_real_, expect = "absent")
claim("text, p. 52 :: Subjects who left a question blank", NA_real_, expect = "absent")
detail("Exclusions the deposit can distinguish",
       str_glue("{main_n$n_dropped} in total; the deposited data carry no attention check field"))

# "All randomizations used Bernoulli random assignment with equal probability 0.5."
# The value pools the five treatment lists; each list's share is printed under it.
list_counts <- map(1:5, \(k) {
  c(treat = t1[[str_glue("List {k} T")]][t1$condition == str_glue("List {k} T")],
    control = t1[[str_glue("List {k} C")]][t1$condition == str_glue("List {k} C")])
})
list_shares <- map_dbl(list_counts, \(x) x[["treat"]] / sum(x))
claim("text, p. 53 :: Bernoulli assignment probability",
      sum(map_dbl(list_counts, "treat")) / sum(map_dbl(list_counts, sum)))
detail("Share assigned to each treatment list", str_flatten_comma(sprintf("%.3f", list_shares)))

# "the 95 percent confidence intervals around the combined estimate are always
# tighter than those around the standard estimate."
# The coverage implied by the multiplier the plotted intervals use.
interval_multiplier <- unique(round((fig_1$ui - fig_1$est) / fig_1$se, 2))
stopifnot(length(interval_multiplier) == 1)
claim("text, p. 54 :: Confidence interval width for the plotted estimates",
      100 * (2 * pnorm(interval_multiplier) - 1))
detail("Multiplier behind the plotted intervals", sprintf("%.2f standard errors", interval_multiplier))

# "Control list responses were drawn from a binomial distribution with a success
# probability of 0.4 and four trials." "The final panel fixes the proportion of
# false confessors at 0.20." "This variability is maximized when p = 0.5." "For
# ease of interpretation, the shading around the conventional power target of 0.80
# is shaded red."
# The first three are settings of the simulation, read out of the scripts that
# generate it; the last is the centre of the band the figure's colour scale shades
# red, on a scale of 100 colours across power from 0 to 1.
claim("appendix C text :: Control list binomial success probability",
      setting_in(figure_a1_source, "baseline_binomial_prob = ([0-9.]+)"))
claim("appendix C text :: Control list binomial trials",
      setting_in(helpers_source, "rbinom\\(N, size = (\\d+)"))
claim("appendix C text :: False confessor proportion fixed in the final panel",
      1 - setting_in(figure_a1_source, "floor\\(cell\\$admitter_n \\* ([0-9.]+)\\)"))
grid_props <- sort(unique(power_grid$prop))
claim("appendix C text :: Binomial probability that maximises variability",
      grid_props[which.max(grid_props * (1 - grid_props))])
claim("appendix C text :: Power target the shading marks",
      mean(setting_in(helpers_source, "power_colors\\[(\\d+):(\\d+)\\] <-")) / 100)

# Published tables, cell by cell ----
# The published tables carry 548 cells between them, which are transcribed once in
# ground_truth/published_claims.csv rather than quoted one sentence at a time. Each
# is compared here against the rewrite's own output, so this file covers every
# cell of every table without reading the ground truth's verdict for any of them.

heading("Published tables, every cell against the page")

long_table <- function(tab, prefix, cols) {
  tab |>
    pivot_longer(-item, names_to = "column", values_to = "value") |>
    transmute(claim_id = as.character(str_glue("{prefix} :: {item}: {rep(cols, times = nrow(tab))}")),
              value)
}

prevalence_cols <- c("Direct", "Direct SE", "Standard list", "Standard list SE",
                     "Combined", "Combined SE", "% reduction in sampling variance")
placebo_cols <- c("beta", "SE", "p-value", "n")
factorial_cols <- c("Direct difference", "Direct SE",
                    "Conventional list difference", "Conventional list SE",
                    "Combined list difference", "Combined list SE")

table_1_cells <- t1 |>
  pivot_longer(-condition, names_to = "crossed_with", values_to = "value") |>
  drop_na(value) |>
  transmute(claim_id = as.character(str_glue("table_1 :: {condition} x {crossed_with}")), value)

table_2_cells <- t2 |>
  pivot_longer(c("Study A Treat", "Study A Control", "Study B Treat", "Study B Control"),
               names_to = "group", values_to = "value") |>
  transmute(claim_id = as.character(str_glue("table_2 :: {level}: {group}")), value)

analysis_cells <- bind_rows(
  long_table(t3, "table_3", prevalence_cols),
  long_table(t4, "table_4", placebo_cols),
  long_table(t5, "table_5", placebo_cols),
  long_table(t6, "table_6", prevalence_cols),
  long_table(t7, "table_7", placebo_cols),
  long_table(t8, "table_8", placebo_cols),
  long_table(ta1, "table_a1", factorial_cols),
  long_table(ta2, "table_a2", prevalence_cols),
  long_table(ta3, "table_a3", placebo_cols),
  long_table(ta4, "table_a4", placebo_cols),
  long_table(ta5, "table_a5", prevalence_cols),
  long_table(ta6, "table_a6", placebo_cols),
  long_table(ta7, "table_a7", placebo_cols),
  long_table(ta8, "table_a8", factorial_cols)
)

table_cells <- bind_rows(table_1_cells, table_2_cells, analysis_cells) |>
  semi_join(published, by = "claim_id")

stopifnot(nrow(table_cells) == sum(str_detect(published$location, "^Table A?\\d+$")))

walk2(table_cells$claim_id, table_cells$value, claim)

# Gates and summary ----
# assert_claims() stops on any failing verdict, on a quantity erratum whose claim
# was not printed as corrected, and on any difference between the claims printed
# here and those the extraction marks needs_block. claim_summary() prints the
# verdict counts, so the exemptions are counted rather than merely allowed.
assert_claims()
invisible(claim_summary())
