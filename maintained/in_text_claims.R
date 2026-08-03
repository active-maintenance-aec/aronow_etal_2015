# aronow_etal_2015/maintained/in_text_claims.R
# Output: none (prints an audit trail to stdout)
# Depends on: maintained/output/, ground_truth/published_claims.csv, helpers.R
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
#   The "covers:" tag on each block names the claim_id or claim_id prefix in
#   ground_truth/published_claims.csv that the block accounts for.
#   build_ground_truth.R reads those tags and stops if a published claim has no
#   block, so a claim cannot quietly lose its coverage here.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

options(width = 200)

read_out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

# Each claim prints as one labelled line, so the output is scannable without
# reading the code beside it.
claim <- function(label, value) cat(sprintf("  %-62s %s\n", paste0(label, ":"), value))

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
# covers: text, p. 50 :: Power at 200 admitters and 20 percent false confessors (%)
claim("Power at 200 admitters, 20 percent false confessors (paper: about 30 percent)",
      sprintf("%.0f percent", 100 * power_of("no false confessions", 200, 0.20)))

# "But when 20 percent of 800 subjects answering \"Yes\" are falsely confessing, the
# test has approximately 80 percent power."
# covers: text, p. 51 :: Power at 800 admitters and 20 percent false confessors (%)
claim("Power at 800 admitters, 20 percent false confessors (paper: about 80 percent)",
      sprintf("%.0f percent", 100 * power_of("no false confessions", 800, 0.20)))

# 5. Application ----

heading("5.1 Experimental Design (pp. 52 to 53)")

# "We recruited a convenience sample of 1,023 subjects from Mechanical Turk."
# covers: text, p. 52 :: Subjects recruited for the main experiment
claim("Subjects recruited for the main experiment (paper: 1,023)",
      format(main_n$n_deposited, big.mark = ","))

# "Two subjects failed this quality check, and we exclude them from the main
# analysis. An additional seven subjects failed to respond to one or more of our
# questions, so we exclude them from the main analysis as well."
# covers: text, p. 52 :: Subjects excluded from the main experiment
claim("Subjects excluded from the main experiment (paper: 2 plus 7)",
      main_n$n_dropped)

# "The resulting sample size is n = 1,014."
# covers: text, p. 52 :: Complete cases in the main experiment
claim("Complete cases in the main experiment (paper: 1,014)",
      format(main_n$n_complete, big.mark = ","))

# "Consistent with our randomization procedure, each cell in the table (with the
# exception of the diagonal) contains approximately one-quarter of the subjects."
# Descriptive. The diagonal the sentence excepts is the two-by-two block each
# randomization forms with itself, where a subject cannot be in both cells, so the
# blocks are dropped by which randomization a condition belongs to rather than by
# the value in the cell. The distribution is printed rather than a verdict.
# covers: text, p. 53 :: Every off-diagonal crossing holds about a quarter of the subjects
randomization_of <- function(x) if_else(str_starts(x, "Study"), "study", str_remove(x, " [TC]$"))

off_block <- t1 |>
  pivot_longer(-condition, names_to = "crossed_with", values_to = "n") |>
  drop_na(n) |>
  filter(randomization_of(condition) != randomization_of(crossed_with)) |>
  mutate(share = 100 * n / main_n$n_complete)

claim("Crossings outside the diagonal blocks", nrow(off_block))
claim("Their share of the complete cases, smallest to largest (paper: about 25 percent)",
      sprintf("%.1f to %.1f percent", min(off_block$share), max(off_block$share)))
claim("Quartiles of that share",
      str_flatten_comma(sprintf("%.1f", quantile(off_block$share, c(0.25, 0.5, 0.75)))))

# "Our subject pool is more likely to be white, male, liberal, well educated, and
# young than the general population."
# Descriptive. Only the first half is checkable here: the deposit carries the
# sample and not the general population, so the shares are printed and the
# comparison is left to the reader.
# covers: text, p. 53 :: The subject pool is disproportionately white, male, liberal, educated and young
share_of <- function(level_names) sum(t2$`Study A Treat`[t2$level %in% level_names])

claim("Study A treatment group, white non-Hispanic", sprintf("%.1f percent", share_of("White, non Hispanic")))
claim("Study A treatment group, male", sprintf("%.1f percent", share_of("Male")))
claim("Study A treatment group, liberal", sprintf("%.1f percent", share_of("Liberal")))
claim("Study A treatment group, some college or more",
      sprintf("%.1f percent", share_of(c("Some College", "4-year College Degree", "Graduate School"))))
claim("Study A treatment group, under 35",
      sprintf("%.1f percent", share_of(c("18 to 24", "25 to 34"))))

heading("5.2 Study A, Direct Questions First (p. 54)")

# "NOTE. n = 500 for all estimates." (note to Table 3)
# covers: table_3 note :: Study A sample size
claim("Study A sample size (paper: 500)", main_n$n_study_a)

# "For example, the direct question estimate Y of the percentage agreeing that
# Muslims should not be allowed to teach in public schools is 11 percent, the list
# experiment estimate is 17 percent, and the combined estimate is 19 percent."
# covers: text, p. 54 :: Direct question estimate for Muslim teachers (%)
# covers: text, p. 54 :: Standard list estimate for Muslim teachers (%)
# covers: text, p. 54 :: Combined estimate for Muslim teachers (%)
claim("Muslim teachers, direct question (paper: 11 percent)",
      sprintf("%.0f percent", 100 * cell_of(t3, "Muslim Teachers", "direct")))
claim("Muslim teachers, standard list (paper: 17 percent)",
      sprintf("%.0f percent", 100 * cell_of(t3, "Muslim Teachers", "conv")))
claim("Muslim teachers, combined (paper: 19 percent)",
      sprintf("%.0f percent", 100 * cell_of(t3, "Muslim Teachers", "combined")))

# "the reductions in estimated sampling variance are dramatic, ranging from 14 to
# 67 percent."
# The full set is printed rather than the endpoints alone, so the range can be
# confirmed by eye rather than inferred from two numbers.
# covers: text, p. 54 :: Smallest reduction in sampling variance, Study A (%)
# covers: text, p. 54 :: Largest reduction in sampling variance, Study A (%)
claim("Study A reductions in sampling variance, all five (paper: 14 to 67 percent)",
      str_flatten_comma(sprintf("%.0f", sort(t3$var_reduc))))

# "As expected, reductions tend to be larger when a larger number of subjects
# respond \"Yes\" to the direct question."
# Descriptive.
# covers: text, p. 54 :: Reductions are larger where more subjects answer Yes
claim("Direct question estimate, ascending",
      str_flatten_comma(sprintf("%.3f", sort(t3$direct))))
claim("Variance reduction in that same order",
      str_flatten_comma(sprintf("%.1f", t3$var_reduc[order(t3$direct)])))
claim("Correlation between the two", sprintf("%.3f", cor(t3$direct, t3$var_reduc)))

# "the 95 percent confidence intervals around the combined estimate are always
# tighter than those around the standard estimate."
# Descriptive. Read off the plotted intervals rather than the standard errors, so
# that the claim is checked against what the figure actually draws.
# covers: text, p. 54 :: The combined interval is always tighter than the standard list interval
interval_widths <- fig_1 |>
  mutate(width = ui - li) |>
  select(item, estimator, width) |>
  pivot_wider(names_from = estimator, values_from = width)

claim("Items where the combined interval is narrower (paper: always)",
      sprintf("%d of %d", sum(interval_widths$`Combined Estimate` <
                                interval_widths$`Standard List Estimate`),
              nrow(interval_widths)))
claim("Ratio of combined to standard list interval width",
      str_flatten_comma(sprintf("%.3f", interval_widths$`Combined Estimate` /
                                  interval_widths$`Standard List Estimate`)))

# "In two cases, we reject the joint null hypothesis of Monotonicity, No Liars, and
# No Design Effects: Public Transportation (p = 0.02) and CNN (p = 0.03)."
# covers: text, p. 54 :: Placebo Test I rejections in Study A
# covers: text, p. 54 :: Placebo Test I p-value quoted for Public Transportation
# covers: text, p. 54 :: Placebo Test I p-value quoted for CNN
claim("Placebo Test I rejections in Study A (paper: two)",
      sprintf("%d of %d, being %s", rejections(t4), nrow(t4), rejecting(t4)))
claim("Public Transportation p-value (paper: 0.02)",
      sprintf("%.2f", cell_of(t4, "Public Transportation", "p_value")))
claim("CNN p-value (paper: 0.03)", sprintf("%.2f", cell_of(t4, "CNN", "p_value")))

# Footnote 1: "The pattern for the other socially sensitive topic, Spanish
# speaking, is reversed: the direct question estimate is greater than both list
# experimental estimates. Our replication study (described below) found the
# opposite pattern, suggesting that this apparent contrast is due to sampling
# variability."
# Descriptive, in two halves.
# covers: footnote 1, p. 54 :: Spanish speaking runs the other way in the main experiment
# covers: footnote 1, p. 54 :: Spanish speaking runs the other way again in the replication
claim("Spanish speaking, main experiment Study A (direct, standard list, combined)",
      str_flatten_comma(sprintf("%.3f", c(cell_of(t3, "Spanish-speaking", "direct"),
                                          cell_of(t3, "Spanish-speaking", "conv"),
                                          cell_of(t3, "Spanish-speaking", "combined")))))
claim("Spanish speaking, replication Study A (direct, standard list, combined)",
      str_flatten_comma(sprintf("%.3f", c(cell_of(ta2, "Spanish-speaking", "direct"),
                                          cell_of(ta2, "Spanish-speaking", "conv"),
                                          cell_of(ta2, "Spanish-speaking", "combined")))))

heading("5.3 Study B, List Experiments First (pp. 56 to 57)")

# "NOTE. n = 514 for all estimates." (note to Table 6)
# covers: table_6 note :: Study B sample size
claim("Study B sample size (paper: 514)", main_n$n_study_b)

# "The direct question estimates are very similar between Studies A and B, none of
# the differences between the estimates is significant at the 0.05 level."
# Descriptive. Table A1 differences Study A against Study B item by item.
# covers: text, p. 56 :: No direct question estimate differs between the studies
direct_z <- ta1$direct_diff / ta1$direct_se
claim("Study A minus Study B direct question z statistics",
      str_flatten_comma(sprintf("%.2f", direct_z)))
claim("Direct question differences rejecting at 0.05 (paper: none)",
      sprintf("%d of %d", sum(2 * pnorm(-abs(direct_z)) < 0.05), nrow(ta1)))

# "The combined estimator produces tighter estimates in Study B as well, with
# estimated sampling variability reductions in a very similar range."
# Descriptive.
# covers: text, p. 56 :: Study B sampling variance reductions fall in a similar range
claim("Study A reductions", sprintf("%.1f to %.1f percent", min(t3$var_reduc), max(t3$var_reduc)))
claim("Study B reductions", sprintf("%.1f to %.1f percent", min(t6$var_reduc), max(t6$var_reduc)))

# "None of the values of the difference-in-means are statistically significantly
# different from 1 using the placebo test, and a joint test via Fisher's method is
# insignificant as well."
# Descriptive, in two halves. The article prints no value for the joint test, so it
# is reconstructed here from the item level p-values it does print.
# covers: text, p. 56 :: No Placebo Test I rejection in Study B
# covers: text, p. 56 :: Fisher's method joint test of Placebo Test I in Study B
claim("Placebo Test I rejections in Study B (paper: none)",
      sprintf("%d of %d", rejections(t7), nrow(t7)))
claim("Study B Placebo Test I p-values", str_flatten_comma(sprintf("%.3f", t7$p_value)))
claim("Fisher's method over those five (paper: insignificant)",
      sprintf("chi-squared %.2f on %d df, p = %.3f",
              -2 * sum(log(t7$p_value)), 2 * nrow(t7),
              pchisq(-2 * sum(log(t7$p_value)), df = 2 * nrow(t7), lower.tail = FALSE)))

# "In two of the five cases, direct questions were significantly affected by the
# treatment list: treated subjects were 8.6 percentage points less likely to
# declare their support for nuclear power and were 13.2 percentage points more
# likely to report watching CNN."
# covers: text, p. 57 :: Placebo Test II rejections in Study B
# covers: text, p. 57 :: Effect of the treatment list on the nuclear power direct question, Study B (pp)
# covers: text, p. 57 :: Effect of the treatment list on the CNN direct question, Study B (pp)
claim("Placebo Test II rejections in Study B (paper: two of five)",
      sprintf("%d of %d, being %s", rejections(t8), nrow(t8), rejecting(t8)))
claim("Nuclear power effect (paper: 8.6 points less likely)",
      sprintf("%.1f percentage points", 100 * cell_of(t8, "Nuclear Power", "beta")))
claim("CNN effect (paper: 13.2 points more likely)",
      sprintf("%.1f percentage points", 100 * cell_of(t8, "CNN", "beta")))

heading("5.4 Replication Study (pp. 57 to 58)")

# "We conducted a replication study following the identical design with 506 new
# Mechanical Turk subjects in a replication of Study A and 506 in a replication of
# Study B."
# covers: text, p. 57 :: Replication Study A sample size
# covers: text, p. 57 :: Replication Study B sample size
claim("Replication Study A sample size (paper: 506)", rep_n$n_study_a)
claim("Replication Study B sample size (paper: 506)", rep_n$n_study_b)

# "The list experimental estimates vary somewhat between the original experiments
# and the replication, but none of these differences are significant (p > 0.05)."
# Descriptive. No published table reports this comparison, so it is built by
# differencing each estimate against its counterpart ten months later.
# covers: text, p. 58 :: No estimate differs between the original experiment and the replication
claim("Original against replication comparisons rejecting at 0.05 (paper: none)",
      sprintf("%d of %d", sum(orig_rep$p_value < 0.05), nrow(orig_rep)))
claim("Smallest p-value across all estimators", sprintf("%.3f", min(orig_rep$p_value)))
claim("Smallest p-value among the standard list estimates",
      sprintf("%.3f", min(orig_rep$p_value[orig_rep$estimator == "conv"])))

# "One of the five placebo tests was significant in Study A, and three of the five
# were significant in Study B."
# Descriptive.
# covers: text, p. 58 :: Placebo Test I rejections in the replication of Study A
# covers: text, p. 58 :: Placebo Test I rejections in the replication of Study B
claim("Replication Placebo Test I rejections, Study A (paper: one of five)",
      sprintf("%d of %d, being %s", rejections(ta3), nrow(ta3), rejecting(ta3)))
claim("Replication Placebo Test I rejections, Study B (paper: three of five)",
      sprintf("%d of %d, being %s", rejections(ta6), nrow(ta6), rejecting(ta6)))

# "Perhaps surprisingly, the effect of the treatment list on direct answers to the
# CNN question presented in table 8 was also replicated."
# Descriptive.
# covers: text, p. 58 :: The CNN treatment list effect replicates
claim("CNN Placebo Test II, main experiment Study B",
      sprintf("%.3f (p = %.3f)", cell_of(t8, "CNN", "beta"), cell_of(t8, "CNN", "p_value")))
claim("CNN Placebo Test II, replication Study B",
      sprintf("%.3f (p = %.3f)", cell_of(ta7, "CNN", "beta"), cell_of(ta7, "CNN", "p_value")))

# 6. Discussion ----

heading("6. Discussion (p. 59)")

# "we reject the joint null hypothesis of Monotonicity, No Liars, and No Design
# Effects for two of the experiments in Study A but fail to reject it for any of
# the five experiments in Study B. Our replication study saw the opposite pattern:
# one rejection in Study A, and three rejections in Study B."
# Descriptive, and a restatement of the Results counts, so the two statements of
# the same quantity are printed together.
# covers: discussion, p. 59 :: Placebo Test I rejections restated for Study A
# covers: discussion, p. 59 :: Placebo Test I rejections restated for the replication
claim("Placebo Test I rejections, main experiment (paper: two in A, none in B)",
      sprintf("Study A %d of 5, Study B %d of 5", rejections(t4), rejections(t7)))
claim("Placebo Test I rejections, replication (paper: one in A, three in B)",
      sprintf("Study A %d of 5, Study B %d of 5", rejections(ta3), rejections(ta6)))

# "Nevertheless, Placebo Test I detected many instances of violated assumptions
# (six of twenty opportunities), suggesting that caution is warranted when
# interpreting list experimental estimates of prevalence."
# covers: discussion, p. 59 :: Placebo Test I rejections across all four studies
# covers: discussion, p. 59 :: Placebo Test I opportunities across all four studies
placebo_i_tables <- list(t4, t7, ta3, ta6)
claim("Placebo Test I rejections across all four studies (paper: six)",
      sum(map_int(placebo_i_tables, rejections)))
claim("Placebo Test I opportunities across all four studies (paper: twenty)",
      sum(map_int(placebo_i_tables, nrow)))

# Appendix C. Power of Placebo Test I ----

heading("Appendix C, Power of Placebo Test I")

# "We varied NYes from 100 to 1000 in steps of 50, the proportion of False
# Confessors, Liars, and Design Affected units from 0 to 1 in steps of 0.01, and
# the success probability of the binomial distribution from 0 to 1 in steps of
# 0.01. We conducted 1,000 simulations of each combination."
# covers: appendix C text :: Smallest number of admitters on the grid
# covers: appendix C text :: Largest number of admitters on the grid
# covers: appendix C text :: Step between admitter counts
# covers: appendix C text :: Step between proportions
# covers: appendix C text :: Simulations per grid cell
# covers: appendix C text :: Grid cells per panel of Figure A1
spec_value <- function(name) grid_spec$value[grid_spec$claim == name]

claim("Admitters on the grid (paper: 100 to 1000 in steps of 50)",
      sprintf("%.0f to %.0f in steps of %.0f", spec_value("Smallest number of admitters"),
              spec_value("Largest number of admitters"), spec_value("Step between admitter counts")))
claim("Proportions on the grid (paper: 0 to 1 in steps of 0.01)",
      sprintf("%.0f to %.0f in steps of %.2f", spec_value("Smallest proportion"),
              spec_value("Largest proportion"), spec_value("Step between proportions")))
claim("Simulations per cell (paper: 1,000)", format(spec_value("Simulations per grid cell"), big.mark = ","))
claim("Cells per panel (paper: 19 by 101)", format(spec_value("Grid cells per panel"), big.mark = ","))

# "When approximately 20% of a sample of 800 confessors falsely confess, lie on the
# treatment list, or change their responses to the non-sensitive items on the
# treatment list, the placebo test achieves 80% power."
# covers: appendix C text :: Power at 800 admitters and 20 percent false confessors (%)
# covers: appendix C text :: Power at 800 admitters and 20 percent liars (%)
# covers: appendix C text :: Power at 800 admitters and 20 percent design affected (%)
# Each is printed both at the appendix's own precision and one decimal finer,
# because two of the three sit within half a point of the boundary the appendix
# rounds at, where the verdict turns on the tie rather than on the estimate.
power_line <- function(violation) {
  value <- 100 * power_of(violation, 800, 0.20)
  sprintf("%.0f percent, and %.1f at one decimal finer", value, value)
}

claim("Power at 800 admitters, 20 percent false confessors (paper: 80%)",
      power_line("no false confessions"))
claim("Power at 800 admitters, 20 percent liars (paper: 80%)",
      power_line("no liars"))
claim("Power at 800 admitters, 20 percent design affected (paper: 80%)",
      power_line("no design effects"))

# Appendix E. Factorial Design ----

heading("Appendix E, Factorial Design")

# "The order in which the direct and list questions does not appear to have had a
# significant impact on the Direct or Combined List estimates of prevalence, but
# does appear to have changed the Conventional List estimates in two cases."
# Descriptive.
# covers: appendix E text :: Question order does not move the direct or combined estimates
reject_count <- function(diff, se) sum(2 * pnorm(-abs(diff / se)) < 0.05)

claim("Direct estimates moved by question order (paper: none)",
      sprintf("%d of %d", reject_count(ta1$direct_diff, ta1$direct_se), nrow(ta1)))
claim("Combined estimates moved by question order (paper: none)",
      sprintf("%d of %d", reject_count(ta1$combined_diff, ta1$combined_se), nrow(ta1)))
claim("Conventional list estimates moved by question order (paper: two)",
      sprintf("%d of %d", reject_count(ta1$conv_diff, ta1$conv_se), nrow(ta1)))

# "The list experimental estimate of the proportion supporting Nuclear power is
# 24.9 percentage points higher when the direct questions are asked first, whereas
# the estimate of those watching CNN is 30.7 percentage points lower when the
# direct questions are asked first."
# covers: appendix E text :: Order effect on the conventional list estimate for nuclear power (pp)
# covers: appendix E text :: Order effect on the conventional list estimate for CNN (pp)
claim("Nuclear power order effect (paper: 24.9 points higher)",
      sprintf("%.1f percentage points", 100 * cell_of(ta1, "Nuclear Power", "conv_diff")))
claim("CNN order effect (paper: 30.7 points lower)",
      sprintf("%.1f percentage points", 100 * cell_of(ta1, "CNN", "conv_diff")))

# Appendix F. Replication Study ----

heading("Appendix F, Replication Study")

# "1019 users started the survey, but 7 either did not complete the survey or
# failed the attention question, leaving 1012 complete cases. 506 subjects
# participated in Study A and 506 participated in Study B."
# covers: appendix F text :: Users who started the replication survey
# covers: appendix F text :: Excluded from the replication
# covers: appendix F text :: Complete cases in the replication
# covers: appendix F text :: Replication Study A sample size
# covers: appendix F text :: Replication Study B sample size
claim("Users who started the replication survey (paper: 1019)", rep_n$n_deposited)
claim("Excluded from the replication (paper: 7)", rep_n$n_dropped)
claim("Complete cases in the replication (paper: 1012)", rep_n$n_complete)
claim("Replication Study A sample size (paper: 506)", rep_n$n_study_a)
claim("Replication Study B sample size (paper: 506)", rep_n$n_study_b)

# "In the original study, two of five questions failed the placebo test in Study A
# and none of the question failed in Study B. The replication shows a different
# pattern: one of five fail in Study A, whereas three of five (at the 5% level or
# greater) fail in Study B."
# Descriptive, and the appendix's own restatement of the Discussion counts.
# covers: appendix F text :: Placebo Test I rejections restated for the main experiment
# covers: appendix F text :: Placebo Test I rejections restated for the replication
claim("Main experiment Placebo Test I (paper: two in A, none in B)",
      sprintf("Study A %d of 5, Study B %d of 5", rejections(t4), rejections(t7)))
claim("Replication Placebo Test I (paper: one in A, three in B)",
      sprintf("Study A %d of 5, Study B %d of 5", rejections(ta3), rejections(ta6)))

# "In the original study, both Nuclear Power and CNN failed the second placebo
# test, but in the replication, only CNN fails."
# Descriptive.
# covers: appendix F text :: Placebo Test II rejections in the main experiment and the replication
claim("Placebo Test II rejections, main experiment Study B (paper: nuclear power and CNN)",
      rejecting(t8))
claim("Placebo Test II rejections, replication Study B (paper: CNN only)", rejecting(ta7))

# "We interpret this result to mean that the effect of the treatment list on direct
# answers to the CNN is not a fluke due to sampling variability but rather a robust
# causal effect on the order of 10 percentage points."
# Descriptive.
# covers: appendix F text :: Size of the replicated CNN treatment list effect
claim("CNN treatment list effect, main experiment (paper: on the order of 10 points)",
      sprintf("%.1f percentage points", 100 * cell_of(t8, "CNN", "beta")))
claim("CNN treatment list effect, replication (paper: on the order of 10 points)",
      sprintf("%.1f percentage points", 100 * cell_of(ta7, "CNN", "beta")))

# Design parameters and structural facts ----
# These are the numbers that describe how the study and the simulation were built
# rather than what they found, so none has a pipeline counterpart and none should
# be given one. Each is verified against the source that settles it: the estimates
# the pipeline already wrote, the script that generates the simulation, or, where
# the deposit records nothing at all, a statement of what it does record.

heading("Design parameters and structural facts")

published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character()))

stated <- function(id) {
  value <- published$value_paper[published$claim_id == id]
  stopifnot(length(value) == 1)
  value
}

figure_a1_source <- read_lines(here::here("maintained", "figure_a1_placebo_i_power.R"))
helpers_source <- read_lines(here::here("maintained", "helpers.R"))

in_source <- function(source_lines, pattern, where) {
  if (any(str_detect(source_lines, fixed(pattern)))) {
    str_glue("set as `{pattern}` in {where}")
  } else {
    str_glue("NOT FOUND in {where}")
  }
}

# "For example, if 20 percent of 200 subjects responding \"Yes\" to the direct
# question are false confessors, the placebo test only has about 30 percent power."
# covers: text, p. 50 :: Admitters in the low power example
claim(str_glue("Admitters in the low power example (paper: {stated('text, p. 50 :: Admitters in the low power example')})"),
      if (200 %in% power_grid$admitter_n) "a row of the simulated grid" else "NOT on the simulated grid")

# "We conducted five list experiments that paralleled five direct questions. In
# three list experiments, we chose topics that are not socially sensitive:
# preferences over alternative energy sources, neighborhood characteristics, and
# news organizations. Two of the five list experiments dealt with racial and
# religious prejudice."
# covers: text, p. 52 :: List experiments conducted
# covers: text, p. 52 :: List experiments on topics that are not socially sensitive
# covers: text, p. 52 :: List experiments on racial and religious prejudice
claim(str_glue("List experiments carried through the tables (paper: {stated('text, p. 52 :: List experiments conducted')})"),
      nrow(t3))
claim("Items the article calls not socially sensitive (paper: three)",
      str_flatten_comma(t3$item[!t3$item %in% c("Spanish-speaking", "Muslim Teachers")]))
claim("Items the article calls sensitive (paper: two)",
      str_flatten_comma(t3$item[t3$item %in% c("Spanish-speaking", "Muslim Teachers")]))

# "We offered subjects $1.00 to complete our survey, which is equivalent to a
# $15.45 hourly rate." And, of the replication, "conducted with a new pool of
# Mechanical Turk respondents ten months after the first study."
# The deposited data carry no payment field and no timestamp, so nothing in the
# pipeline can speak to these. They are recorded and left as the article states.
# covers: text, p. 52 :: Payment per subject (dollars)
# covers: text, p. 52 :: Equivalent hourly rate (dollars)
# covers: appendix F text :: Months between the two experiments
claim("Payment per subject", str_glue("article states {stated('text, p. 52 :: Payment per subject (dollars)')}; the deposited data carry no payment field"))
claim("Equivalent hourly rate", str_glue("article states {stated('text, p. 52 :: Equivalent hourly rate (dollars)')}; the deposited data carry no completion time"))
claim("Months between the experiments", str_glue("article states {stated('appendix F text :: Months between the two experiments')}; the deposited data carry no timestamp"))

# "Two subjects failed this quality check ... An additional seven subjects failed to
# respond to one or more of our questions."
# The deposit records the incomplete responses and nothing that identifies a failed
# attention check, so only the total is recoverable.
# covers: text, p. 52 :: Subjects who failed the attention question
# covers: text, p. 52 :: Subjects who left a question blank
claim("Exclusions the article separates", str_glue("{stated('text, p. 52 :: Subjects who failed the attention question')} plus {stated('text, p. 52 :: Subjects who left a question blank')}"))
claim("Exclusions the deposit can distinguish",
      str_glue("{main_n$n_dropped} in total; the deposited data carry no attention check field"))

# "All randomizations used Bernoulli random assignment with equal probability 0.5."
# covers: text, p. 53 :: Bernoulli assignment probability
list_shares <- map_dbl(1:5, \(k) {
  treat <- t1[[str_glue("List {k} T")]][t1$condition == str_glue("List {k} T")]
  control <- t1[[str_glue("List {k} C")]][t1$condition == str_glue("List {k} C")]
  treat / (treat + control)
})
claim(str_glue("Share assigned to each treatment list (paper: {stated('text, p. 53 :: Bernoulli assignment probability')})"),
      str_flatten_comma(sprintf("%.3f", list_shares)))

# "the 95 percent confidence intervals around the combined estimate are always
# tighter than those around the standard estimate."
# covers: text, p. 54 :: Confidence interval width for the plotted estimates
claim(str_glue("Multiplier behind the plotted intervals (paper: {stated('text, p. 54 :: Confidence interval width for the plotted estimates')} percent)"),
      sprintf("%.2f standard errors", unique(round((fig_1$ui - fig_1$est) / fig_1$se, 2))))

# "Control list responses were drawn from a binomial distribution with a success
# probability of 0.4 and four trials." "The final panel fixes the proportion of
# false confessors at 0.20." "This variability is maximized when p = 0.5." "For
# ease of interpretation, the shading around the conventional power target of 0.80
# is shaded red."
# The first three are settings of the simulation, verified against the scripts that
# generate it; the last is a fact about the figure's shading.
# covers: appendix C text :: Control list binomial success probability
# covers: appendix C text :: Control list binomial trials
# covers: appendix C text :: False confessor proportion fixed in the final panel
# covers: appendix C text :: Binomial probability that maximises variability
# covers: appendix C text :: Power target the shading marks
claim("Binomial success probability for the control list (paper: 0.4)",
      in_source(figure_a1_source, "baseline_binomial_prob = 0.4", "figure_a1_placebo_i_power.R"))
claim("Binomial trials for the control list (paper: four)",
      in_source(helpers_source, "rbinom(N, size = 4", "helpers.R"))
claim("True admitters fixed in the final panel (paper: 0.20 false confessors)",
      in_source(figure_a1_source, "cell$admitter_n * 0.80", "figure_a1_placebo_i_power.R"))
claim("Binomial probability on the grid that maximises variance (paper: 0.5)",
      sprintf("%.2f", unique(sort(power_grid$prop))[which.max(unique(sort(power_grid$prop)) *
                                                               (1 - unique(sort(power_grid$prop))))]))
claim("Power target the shading marks (paper: 0.80)",
      in_source(helpers_source, "power_colors[75:85]", "helpers.R"))

# Published tables, cell by cell ----
# The published tables carry 548 cells between them, which are transcribed once in
# ground_truth/published_claims.csv rather than quoted one sentence at a time. Each
# is compared here against the rewrite's own output, printed to the precision the
# published page uses, so this file covers every cell of every table without
# reading the ground truth's verdict for any of them.

heading("Published tables, every cell against the page")

long_table <- function(tab, table_figure, cols) {
  tab |>
    pivot_longer(-item, names_to = "column", values_to = "value") |>
    transmute(claim_id = as.character(str_glue("{table_figure} :: {item}: {rep(cols, times = nrow(tab))}")),
              value)
}

prevalence_cols <- c("Direct", "Direct SE", "Standard list", "Standard list SE",
                     "Combined", "Combined SE", "% reduction in sampling variance")
placebo_cols <- c("beta", "SE", "p-value", "n")
factorial_cols <- c("Direct difference", "Direct SE",
                    "Conventional list difference", "Conventional list SE",
                    "Combined list difference", "Combined list SE")

# covers: table_1 ::
table_1_cells <- t1 |>
  pivot_longer(-condition, names_to = "crossed_with", values_to = "value") |>
  drop_na(value) |>
  transmute(claim_id = as.character(str_glue("table_1 :: {condition} x {crossed_with}")), value)

# covers: table_2 ::
table_2_cells <- t2 |>
  pivot_longer(c("Study A Treat", "Study A Control", "Study B Treat", "Study B Control"),
               names_to = "group", values_to = "value") |>
  transmute(claim_id = as.character(str_glue("table_2 :: {level}: {group}")), value)

# covers: table_3 ::
# covers: table_4 ::
# covers: table_5 ::
# covers: table_6 ::
# covers: table_7 ::
# covers: table_8 ::
# covers: table_a1 ::
# covers: table_a2 ::
# covers: table_a3 ::
# covers: table_a4 ::
# covers: table_a5 ::
# covers: table_a6 ::
# covers: table_a7 ::
# covers: table_a8 ::
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
  inner_join(published, by = "claim_id") |>
  mutate(
    decimals = if_else(str_detect(value_paper, fixed(".")),
                       nchar(str_remove(value_paper, "^[^.]*\\.")), 0L),
    printed = sprintf(paste0("%.", decimals, "f"), value),
    agrees = printed == value_paper
  )

stopifnot(nrow(table_cells) == sum(str_detect(published$location, "^table_(\\d+|a\\d+)$")))

table_cells |>
  mutate(table_figure = str_remove(claim_id, " :: .*$")) |>
  summarize(cells = n(), reproduced = sum(agrees), .by = table_figure) |>
  pwalk(\(table_figure, cells, reproduced)
        claim(str_glue("{table_figure}, cells reproduced at the published precision"),
              sprintf("%d of %d", reproduced, cells)))

claim("All published table cells reproduced",
      sprintf("%d of %d", sum(table_cells$agrees), nrow(table_cells)))

if (any(!table_cells$agrees)) {
  print(table_cells |> filter(!agrees) |> select(claim_id, value_paper, printed), n = Inf)
}
