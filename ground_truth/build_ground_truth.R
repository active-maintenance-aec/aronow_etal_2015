# aronow_etal_2015/ground_truth/build_ground_truth.R
# Output: ground_truth/aronow_etal_2015_ground_truth.csv,
#         ground_truth/float_coverage.csv
# Depends on: ground_truth/published_claims.csv, errata_entries.csv,
#             ground_truth/archive_values.csv (run_archive.R),
#             maintained/output/ (run run_all.R first)
# Description: Assemble the ground truth table. Everything the article and the
#   online supplementary materials print is transcribed once, into
#   published_claims.csv, and this script never types a published number of its
#   own. value_script is read back from the deposited scripts' own run and
#   value_rewrite from maintained/output/, so neither column can drift from the
#   code it describes. Every pipeline and descriptive claim must find a computed
#   counterpart here or the build stops.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

balance_groups <- c("Study A Treat", "Study A Control", "Study B Treat", "Study B Control")

prevalence_cols <- c("Direct", "Direct SE", "Standard list", "Standard list SE",
                     "Combined", "Combined SE", "% reduction in sampling variance")
placebo_cols <- c("beta", "SE", "p-value", "n")
factorial_cols <- c("Direct difference", "Direct SE",
                    "Conventional list difference", "Conventional list SE",
                    "Combined list difference", "Combined list SE")

# The published claims ----
# Every numeric token in the article and the online supplement, extracted
# exhaustively and classified by hand. value_paper is carried as the string the
# published page prints, never as a number, because a double does not record how
# many decimals were printed: 0.80 and 0.8 are the same double.
published <- read_csv(here::here("ground_truth", "published_claims.csv"),
                      col_types = cols(.default = col_character())) |>
  mutate(digits = as.integer(digits))

stopifnot(
  identical(names(published), c("claim_id", "location", "claim_type", "claim", "value_paper",
                                "digits", "comparison", "expect", "needs_block", "notes")),
  !any(duplicated(published$claim_id)),
  all(published$claim_type %in% c("pipeline", "definitional", "structural",
                                  "transcribed", "descriptive")),
  all(published$comparison %in% c("==", "<", "<=", ">", ">=", "approx", NA)),
  all(published$expect %in% c("range", "derived", "absent", "shape", NA)),
  all(published$needs_block %in% c("TRUE", "FALSE"))
)

# The extraction's digits are the precision the page prints. This build carries no
# override of its own, so the column has to agree with the printed string everywhere.
stopifnot(identical(published$digits, excheckr::claim_digits(published$value_paper)))

# A value agrees when it prints, at the page's own precision, to the digits the page
# prints. This is a string comparison rather than a numeric tolerance, because a
# tolerance fails in both directions: it passes a value the page never printed when
# the tolerance is read off the wrong number of decimals, and it fails a true match
# sitting exactly on a rounding boundary.
printed_as_paper <- function(value, digits) {
  printed <- sprintf(paste0("%.", replace_na(digits, 0L), "f"), replace_na(value, 0))
  if_else(is.na(value) | is.na(digits), NA_character_, printed)
}

# The rewrite's own values, read back out of maintained/output/ ----
# prefix is the claim_id prefix the extraction keys each table's cells by.
rewrite_analysis <- function(prefix, file, cols) {
  out(file) |>
    pivot_longer(-item, names_to = "column", values_to = "value_rewrite") |>
    transmute(
      prefix = prefix,
      claim = as.character(str_glue("{item}: {rep(cols, times = 5)}")),
      value_rewrite
    )
}

analysis_files <- tribble(
  ~prefix, ~file, ~cols,
  "table_3", "table_3_study_a_prevalence.csv", prevalence_cols,
  "table_4", "table_4_study_a_placebo_i.csv", placebo_cols,
  "table_5", "table_5_study_a_placebo_ii.csv", placebo_cols,
  "table_6", "table_6_study_b_prevalence.csv", prevalence_cols,
  "table_7", "table_7_study_b_placebo_i.csv", placebo_cols,
  "table_8", "table_8_study_b_placebo_ii.csv", placebo_cols,
  "table_a1", "table_a1_factorial.csv", factorial_cols,
  "table_a2", "table_a2_rep_study_a_prevalence.csv", prevalence_cols,
  "table_a3", "table_a3_rep_study_a_placebo_i.csv", placebo_cols,
  "table_a4", "table_a4_rep_study_a_placebo_ii.csv", placebo_cols,
  "table_a5", "table_a5_rep_study_b_prevalence.csv", prevalence_cols,
  "table_a6", "table_a6_rep_study_b_placebo_i.csv", placebo_cols,
  "table_a7", "table_a7_rep_study_b_placebo_ii.csv", placebo_cols,
  "table_a8", "table_a8_rep_factorial.csv", factorial_cols
)

rewrite_table_1 <- out("table_1_treatment_ns.csv") |>
  pivot_longer(-condition, names_to = "crossed_with", values_to = "value_rewrite") |>
  transmute(prefix = "table_1",
            claim = as.character(str_glue("{condition} x {crossed_with}")),
            value_rewrite) |>
  drop_na(value_rewrite)

rewrite_table_2 <- out("table_2_covariate_balance.csv") |>
  pivot_longer(all_of(balance_groups), names_to = "group", values_to = "value_rewrite") |>
  transmute(prefix = "table_2",
            claim = as.character(str_glue("{level}: {group}")),
            value_rewrite)

float_rewrite <- bind_rows(
  rewrite_table_1,
  rewrite_table_2,
  pmap(analysis_files, rewrite_analysis) |> list_rbind()
) |>
  transmute(claim_id = as.character(str_glue("{prefix} :: {claim}")), value_rewrite)

# archive_values.csv is run_archive.R's intermediate, keyed by the same claim_id
# prefixes in its table_figure column.
archive <- read_csv(here::here("ground_truth", "archive_values.csv"), show_col_types = FALSE)

float_archive <- archive |>
  transmute(claim_id = as.character(str_glue("{table_figure} :: {claim}")), value_script)

arc <- function(table_figure, claim) {
  value <- archive$value_script[archive$table_figure == table_figure & archive$claim == claim]
  stopifnot(length(value) == 1)
  value
}

# The pipeline outputs the prose claims are read from ----
sizes <- out("text_sample_sizes.csv")
main_sizes <- filter(sizes, experiment == "main")
rep_sizes <- filter(sizes, experiment == "replication")

t1 <- out("table_1_treatment_ns.csv")
t2 <- out("table_2_covariate_balance.csv")
t3 <- out("table_3_study_a_prevalence.csv")
t4 <- out("table_4_study_a_placebo_i.csv")
t6 <- out("table_6_study_b_prevalence.csv")
t7 <- out("table_7_study_b_placebo_i.csv")
t8 <- out("table_8_study_b_placebo_ii.csv")
ta1 <- out("table_a1_factorial.csv")
ta2 <- out("table_a2_rep_study_a_prevalence.csv")
ta7 <- out("table_a7_rep_study_b_placebo_ii.csv")

f1 <- out("figure_1_study_a_prevalence.csv")
f2 <- out("figure_2_study_b_prevalence.csv")
fa1 <- out("figure_a1_placebo_i_power.csv")
a2_check <- out("text_figure_a2_archive_grid.csv")
sampler <- out("text_placebo_i_sampler.csv")
grid_spec <- out("text_figure_a1_grid_spec.csv")
placebo_cells <- out("text_placebo_summaries.csv")
placebo_joint <- out("text_placebo_joint_tests.csv")
orig_vs_rep <- out("text_original_vs_replication.csv")

# Every join in this build goes through this one helper. It asserts the key is
# unique on both sides, so a duplicated key cannot silently multiply rows, and that
# the join preserved the row count and matched every row, so a key present on one
# side only cannot leave a column of NA that reads as "unverifiable" rather than as
# the wiring fault it is.
join_1to1 <- function(x, y, by, all_matched = TRUE) {
  stopifnot(
    nrow(distinct(x, across(all_of(by)))) == nrow(x),
    nrow(distinct(y, across(all_of(by)))) == nrow(y)
  )
  joined <- left_join(x, y, by = by)
  stopifnot(nrow(joined) == nrow(x))
  if (all_matched) stopifnot(!anyNA(joined[setdiff(names(y), by)]))
  joined
}

# Figures 1 and 2 plot the Table 3 and Table 6 estimates. The check is that the
# plotted numbers are those numbers, measured rather than asserted. The two frames
# are joined on (item, estimator) rather than sorted into alignment, so a renamed
# estimator or a dropped item stops the build instead of quietly comparing the
# wrong pairs.
plotted_gap <- function(fig, tab) {
  long <- tab |>
    pivot_longer(c(direct, conv, combined), names_to = "estimator", values_to = "est")
  drawn <- fig |>
    mutate(estimator = recode_values(as.character(estimator),
                                     "Direct Estimate" ~ "direct",
                                     "Standard List Estimate" ~ "conv",
                                     "Combined Estimate" ~ "combined")) |>
    select(item, estimator, est_plotted = est)
  joined <- join_1to1(long, drawn, c("item", "estimator"))
  stopifnot(nrow(long) == nrow(fig))
  max(abs(joined$est - joined$est_plotted))
}

power_at <- function(panel_name, n_admitters, proportion) {
  value <- fa1$power[fa1$panel == panel_name & fa1$admitter_n == n_admitters &
                       abs(fa1$prop - proportion) < 1e-9]
  stopifnot(length(value) == 1)
  value
}

one_value <- function(d, claim_text) {
  value <- d$value[d$claim == claim_text]
  stopifnot(length(value) == 1)
  value
}

a2 <- function(claim_text) one_value(a2_check, claim_text)
spec <- function(claim_text) one_value(grid_spec, claim_text)

rejects <- function(which_experiment, which_study, which_test) {
  placebo_joint$n_rejects_at_05[placebo_joint$experiment == which_experiment &
                                  placebo_joint$study == which_study &
                                  placebo_joint$test == which_test]
}

joint_p <- function(which_experiment, which_study, which_test) {
  placebo_joint$p_joint[placebo_joint$experiment == which_experiment &
                          placebo_joint$study == which_study &
                          placebo_joint$test == which_test]
}

rejecting_items <- function(which_experiment, which_study, which_test) {
  placebo_cells |>
    filter(experiment == which_experiment, study == which_study,
           test == which_test, rejects_at_05) |>
    pull(item) |>
    str_flatten_comma(last = " and ")
}

item_value <- function(d, which_item, column) d[[column]][d$item == which_item]

# Table 1's crossings as a share of the complete cases. The diagonal the article
# excepts is the two-by-two block each randomization forms with itself, where a
# subject cannot appear in both cells, so the blocks are dropped by the variable
# each condition belongs to rather than by the value in the cell.
randomization <- function(x) if_else(str_starts(x, "Study"), "study", str_remove(x, " [TC]$"))

crossings <- t1 |>
  pivot_longer(-condition, names_to = "crossed_with", values_to = "n") |>
  drop_na(n) |>
  filter(randomization(condition) != randomization(crossed_with)) |>
  mutate(share = n / main_sizes$n_complete)

# The five demographic majorities the article claims for its subject pool, read
# off the Study A treatment column of the balance table.
pool_share <- function(level_name) {
  sum(t2$`Study A Treat`[t2$level == level_name])
}

young_share <- sum(t2$`Study A Treat`[t2$level %in% c("18 to 24", "25 to 34")])
college_share <- sum(t2$`Study A Treat`[t2$level %in% c("4-year College Degree",
                                                        "Graduate School",
                                                        "Some College")])

# The computed counterpart of every prose claim ----
# Keyed by claim_id, so a claim whose label changes in published_claims.csv fails
# to join and stops the build rather than silently losing its counterpart.
computed <- tribble(
  ~claim_id, ~value_script, ~value_rewrite, ~evidence, ~notes,

  "text, p. 50 :: Power at 200 admitters and 20 percent false confessors (%)",
    NA, 100 * power_at("no false confessions", 200, 0.20), "",
    "The article hedges this as approximate. A grid cell is 1,000 simulated experiments and the deposit sets no seed",
  "text, p. 51 :: Power at 800 admitters and 20 percent false confessors (%)",
    NA, 100 * power_at("no false confessions", 800, 0.20), "", "",
  "text, p. 52 :: Subjects recruited for the main experiment",
    NA, main_sizes$n_deposited, "", "",
  "text, p. 52 :: Subjects excluded from the main experiment",
    NA, main_sizes$n_dropped, "",
    "The article gives this as two failed attention checks plus seven incomplete responses; the deposited data cannot separate the two",
  "text, p. 52 :: Complete cases in the main experiment",
    NA, main_sizes$n_complete, "", "",
  "text, p. 53 :: Every off-diagonal crossing holds about a quarter of the subjects",
    NA, NA,
    str_glue("{nrow(crossings)} crossings outside the diagonal blocks, holding ",
             "{min(crossings$n)} to {max(crossings$n)} subjects, which is ",
             "{round(100 * min(crossings$share), 1)} to {round(100 * max(crossings$share), 1)} ",
             "percent of the {main_sizes$n_complete} complete cases against a quarter at 25.0"),
    "",
  "text, p. 53 :: The subject pool is disproportionately white, male, liberal, educated and young",
    NA, NA,
    str_glue("In the Study A treatment group: white {round(pool_share('White, non Hispanic'), 1)}, ",
             "male {round(pool_share('Male'), 1)}, liberal {round(pool_share('Liberal'), 1)}, ",
             "some college or more {round(college_share, 1)}, under 35 {round(young_share, 1)} percent"),
    "The comparison the sentence makes is against the general population, which the deposit does not carry",
  "table_3 note :: Study A sample size",
    arc("table_1", "Study A x Study A"), main_sizes$n_study_a, "", "",
  "text, p. 54 :: Direct question estimate for Muslim teachers (%)",
    100 * arc("table_3", "Muslim Teachers: Direct"),
    100 * item_value(t3, "Muslim Teachers", "direct"), "", "",
  "text, p. 54 :: Standard list estimate for Muslim teachers (%)",
    100 * arc("table_3", "Muslim Teachers: Standard list"),
    100 * item_value(t3, "Muslim Teachers", "conv"), "", "",
  "text, p. 54 :: Combined estimate for Muslim teachers (%)",
    100 * arc("table_3", "Muslim Teachers: Combined"),
    100 * item_value(t3, "Muslim Teachers", "combined"), "", "",
  "text, p. 54 :: Smallest reduction in sampling variance, Study A (%)",
    min(archive$value_script[archive$table_figure == "table_3" &
                               str_detect(archive$claim, "% reduction")]),
    min(t3$var_reduc), "", "The article gives the range as 14 to 67 percent",
  "text, p. 54 :: Largest reduction in sampling variance, Study A (%)",
    max(archive$value_script[archive$table_figure == "table_3" &
                               str_detect(archive$claim, "% reduction")]),
    max(t3$var_reduc), "", "",
  "text, p. 54 :: Reductions are larger where more subjects answer Yes",
    NA, NA,
    str_glue("Across the five items the direct question estimate and the variance ",
             "reduction correlate at {round(cor(t3$direct, t3$var_reduc), 3)}; the ",
             "reductions in ascending order of the direct estimate are ",
             "{str_flatten_comma(round(t3$var_reduc[order(t3$direct)], 1))}"),
    "",
  "text, p. 54 :: The combined interval is always tighter than the standard list interval",
    NA, NA,
    str_glue("The combined standard error is smaller than the standard list ",
             "standard error in {sum(t3$combined_se < t3$conv_se)} of {nrow(t3)} items; ",
             "the ratios are {str_flatten_comma(round(t3$combined_se / t3$conv_se, 3))}"),
    "",
  "text, p. 54 :: Placebo Test I rejections in Study A",
    NA, rejects("main", "Study A", "Placebo Test I"),
    str_glue("{rejects('main', 'Study A', 'Placebo Test I')} of {nrow(t4)} reject at 0.05: ",
             "{rejecting_items('main', 'Study A', 'Placebo Test I')}. p-values ",
             "{str_flatten_comma(round(t4$p_value, 3))}"),
    "",
  "text, p. 54 :: Placebo Test I p-value quoted for Public Transportation",
    arc("table_4", "Public Transportation: p-value"),
    item_value(t4, "Public Transportation", "p_value"), "", "",
  "text, p. 54 :: Placebo Test I p-value quoted for CNN",
    arc("table_4", "CNN: p-value"), item_value(t4, "CNN", "p_value"), "", "",
  "footnote 1, p. 54 :: Spanish speaking runs the other way in the main experiment",
    NA, NA,
    str_glue("Study A Spanish-speaking: direct {round(item_value(t3, 'Spanish-speaking', 'direct'), 3)}, ",
             "standard list {round(item_value(t3, 'Spanish-speaking', 'conv'), 3)}, ",
             "combined {round(item_value(t3, 'Spanish-speaking', 'combined'), 3)}"),
    "",
  "footnote 1, p. 54 :: Spanish speaking runs the other way again in the replication",
    NA, NA,
    str_glue("Replication Study A Spanish-speaking: direct {round(item_value(ta2, 'Spanish-speaking', 'direct'), 3)}, ",
             "standard list {round(item_value(ta2, 'Spanish-speaking', 'conv'), 3)}, ",
             "combined {round(item_value(ta2, 'Spanish-speaking', 'combined'), 3)}"),
    "",
  "table_6 note :: Study B sample size",
    arc("table_1", "Study B x Study B"), main_sizes$n_study_b, "", "",
  "text, p. 56 :: No direct question estimate differs between the studies",
    NA, NA,
    str_glue("Study A minus Study B direct differences over their standard errors: ",
             "{str_flatten_comma(round(ta1$direct_diff / ta1$direct_se, 2))}; ",
             "{sum(2 * pnorm(-abs(ta1$direct_diff / ta1$direct_se)) < 0.05)} of ",
             "{nrow(ta1)} reject at 0.05"),
    "",
  "text, p. 56 :: Study B sampling variance reductions fall in a similar range",
    NA, NA,
    str_glue("Study A reductions run {round(min(t3$var_reduc), 1)} to {round(max(t3$var_reduc), 1)} ",
             "percent and Study B reductions {round(min(t6$var_reduc), 1)} to ",
             "{round(max(t6$var_reduc), 1)} percent"),
    "",
  "text, p. 56 :: No Placebo Test I rejection in Study B",
    NA, rejects("main", "Study B", "Placebo Test I"),
    str_glue("{rejects('main', 'Study B', 'Placebo Test I')} of {nrow(t7)} reject at 0.05; ",
             "p-values {str_flatten_comma(round(t7$p_value, 3))}"),
    "",
  "text, p. 56 :: Fisher's method joint test of Placebo Test I in Study B",
    NA, joint_p("main", "Study B", "Placebo Test I"),
    str_glue("Fisher's method over the five Study B p-values gives ",
             "chi-squared {round(placebo_joint$chi_squared[placebo_joint$experiment == 'main' & placebo_joint$study == 'Study B' & placebo_joint$test == 'Placebo Test I'], 2)} ",
             "on 10 degrees of freedom, p = {round(joint_p('main', 'Study B', 'Placebo Test I'), 3)}"),
    "The article reports this test and prints no value for it, so the statistic is reconstructed from the item level p-values it does print",
  "text, p. 57 :: Placebo Test II rejections in Study B",
    NA, rejects("main", "Study B", "Placebo Test II"),
    str_glue("{rejects('main', 'Study B', 'Placebo Test II')} of {nrow(t8)} reject at 0.05: ",
             "{rejecting_items('main', 'Study B', 'Placebo Test II')}. p-values ",
             "{str_flatten_comma(round(t8$p_value, 3))}"),
    "",
  "text, p. 57 :: Effect of the treatment list on the nuclear power direct question, Study B (pp)",
    abs(100 * arc("table_8", "Nuclear Power: beta")),
    abs(100 * item_value(t8, "Nuclear Power", "beta")), "",
    "The article gives the magnitude and states the direction in words: treated subjects were less likely to declare support",
  "text, p. 57 :: Effect of the treatment list on the CNN direct question, Study B (pp)",
    abs(100 * arc("table_8", "CNN: beta")),
    abs(100 * item_value(t8, "CNN", "beta")), "",
    "The article gives the magnitude and states the direction in words: treated subjects were more likely to report watching CNN",
  "text, p. 57 :: Replication Study A sample size",
    NA, rep_sizes$n_study_a, "", "",
  "text, p. 57 :: Replication Study B sample size",
    NA, rep_sizes$n_study_b, "", "",
  "text, p. 58 :: No estimate differs between the original experiment and the replication",
    NA, NA,
    str_glue("{sum(orig_vs_rep$rejects_at_05)} of {nrow(orig_vs_rep)} original against ",
             "replication comparisons reject at 0.05; the smallest p-value is ",
             "{round(min(orig_vs_rep$p_value), 3)}, and among the standard list ",
             "estimates alone it is ",
             "{round(min(orig_vs_rep$p_value[orig_vs_rep$estimator == 'conv']), 3)}"),
    "No published table reports this comparison; it is built by differencing each estimate against its counterpart in the other experiment",
  "text, p. 58 :: Placebo Test I rejections in the replication of Study A",
    NA, rejects("replication", "Study A", "Placebo Test I"),
    str_glue("{rejects('replication', 'Study A', 'Placebo Test I')} of 5 reject at 0.05: ",
             "{rejecting_items('replication', 'Study A', 'Placebo Test I')}"),
    "",
  "text, p. 58 :: Placebo Test I rejections in the replication of Study B",
    NA, rejects("replication", "Study B", "Placebo Test I"),
    str_glue("{rejects('replication', 'Study B', 'Placebo Test I')} of 5 reject at 0.05: ",
             "{rejecting_items('replication', 'Study B', 'Placebo Test I')}"),
    "",
  "text, p. 58 :: The CNN treatment list effect replicates",
    NA, NA,
    str_glue("CNN Placebo Test II: main experiment Study B ",
             "{round(item_value(t8, 'CNN', 'beta'), 3)} (p = {round(item_value(t8, 'CNN', 'p_value'), 3)}), ",
             "replication Study B {round(item_value(ta7, 'CNN', 'beta'), 3)} ",
             "(p = {round(item_value(ta7, 'CNN', 'p_value'), 3)})"),
    "",
  "discussion, p. 59 :: Placebo Test I rejections restated for Study A",
    NA, rejects("main", "Study A", "Placebo Test I"),
    str_glue("Main experiment Placebo Test I: Study A ",
             "{rejects('main', 'Study A', 'Placebo Test I')} of 5, Study B ",
             "{rejects('main', 'Study B', 'Placebo Test I')} of 5"),
    "",
  "discussion, p. 59 :: Placebo Test I rejections restated for the replication",
    NA, rejects("replication", "Study A", "Placebo Test I"),
    str_glue("Replication Placebo Test I: Study A ",
             "{rejects('replication', 'Study A', 'Placebo Test I')} of 5, Study B ",
             "{rejects('replication', 'Study B', 'Placebo Test I')} of 5"),
    "",
  "discussion, p. 59 :: Placebo Test I rejections across all four studies",
    NA, sum(placebo_joint$n_rejects_at_05[placebo_joint$test == "Placebo Test I"]),
    "", "",
  "discussion, p. 59 :: Placebo Test I opportunities across all four studies",
    NA, sum(placebo_joint$tests[placebo_joint$test == "Placebo Test I"]), "", "",
  "appendix C text :: Smallest number of admitters on the grid",
    NA, spec("Smallest number of admitters"), "", "",
  "appendix C text :: Largest number of admitters on the grid",
    NA, spec("Largest number of admitters"), "", "",
  "appendix C text :: Step between admitter counts",
    NA, spec("Step between admitter counts"), "", "",
  "appendix C text :: Step between proportions",
    NA, spec("Step between proportions"), "", "",
  "appendix C text :: Simulations per grid cell",
    NA, spec("Simulations per grid cell"), "", "",
  "appendix C text :: Grid cells per panel of Figure A1",
    NA, spec("Grid cells per panel"), "",
    "The appendix prints the sequences rather than their product",
  "appendix C text :: Power at 800 admitters and 20 percent false confessors (%)",
    NA, 100 * power_at("no false confessions", 800, 0.20), "",
    "The appendix prints this as 80% and hedges the settings as approximate",
  "appendix C text :: Power at 800 admitters and 20 percent liars (%)",
    NA, 100 * power_at("no liars", 800, 0.20), "", "",
  "appendix C text :: Power at 800 admitters and 20 percent design affected (%)",
    NA, 100 * power_at("no design effects", 800, 0.20), "", "",
  "appendix E text :: Question order does not move the direct or combined estimates",
    NA, NA,
    str_glue("Rejections at 0.05 out of five items: direct ",
             "{sum(2 * pnorm(-abs(ta1$direct_diff / ta1$direct_se)) < 0.05)}, ",
             "conventional list {sum(2 * pnorm(-abs(ta1$conv_diff / ta1$conv_se)) < 0.05)}, ",
             "combined {sum(2 * pnorm(-abs(ta1$combined_diff / ta1$combined_se)) < 0.05)}"),
    "",
  "appendix E text :: Order effect on the conventional list estimate for nuclear power (pp)",
    100 * arc("table_a1", "Nuclear Power: Conventional list difference"),
    100 * item_value(ta1, "Nuclear Power", "conv_diff"), "", "",
  "appendix E text :: Order effect on the conventional list estimate for CNN (pp)",
    abs(100 * arc("table_a1", "CNN: Conventional list difference")),
    abs(100 * item_value(ta1, "CNN", "conv_diff")), "",
    "The appendix gives the magnitude and states the direction in words: lower when the direct questions are asked first",
  "appendix F text :: Users who started the replication survey",
    NA, rep_sizes$n_deposited, "", "",
  "appendix F text :: Excluded from the replication",
    NA, rep_sizes$n_dropped, "", "",
  "appendix F text :: Complete cases in the replication",
    NA, rep_sizes$n_complete, "", "",
  "appendix F text :: Replication Study A sample size",
    NA, rep_sizes$n_study_a, "", "",
  "appendix F text :: Replication Study B sample size",
    NA, rep_sizes$n_study_b, "", "",
  "appendix F text :: Placebo Test I rejections restated for the main experiment",
    NA, rejects("main", "Study A", "Placebo Test I"),
    str_glue("Main experiment Placebo Test I: Study A ",
             "{rejects('main', 'Study A', 'Placebo Test I')} of 5, Study B ",
             "{rejects('main', 'Study B', 'Placebo Test I')} of 5"),
    "",
  "appendix F text :: Placebo Test I rejections restated for the replication",
    NA, rejects("replication", "Study A", "Placebo Test I"),
    str_glue("Replication Placebo Test I: Study A ",
             "{rejects('replication', 'Study A', 'Placebo Test I')} of 5, Study B ",
             "{rejects('replication', 'Study B', 'Placebo Test I')} of 5"),
    "",
  "appendix F text :: Placebo Test II rejections in the main experiment and the replication",
    NA, NA,
    str_glue("Placebo Test II rejections at 0.05: main experiment Study B ",
             "{rejecting_items('main', 'Study B', 'Placebo Test II')}; replication Study B ",
             "{rejecting_items('replication', 'Study B', 'Placebo Test II')}"),
    "",
  "appendix F text :: Size of the replicated CNN treatment list effect",
    NA, NA,
    str_glue("CNN Placebo Test II effect in percentage points: main experiment ",
             "{round(100 * item_value(t8, 'CNN', 'beta'), 1)}, replication ",
             "{round(100 * item_value(ta7, 'CNN', 'beta'), 1)}"),
    ""
) |>
  mutate(across(c(evidence, notes), as.character))

# Join the article to the pipeline ----
# The deposited scripts and the rewrite must produce the same set of cells, which
# is asserted before the join rather than discovered as a column of NA inside it.
stopifnot(setequal(float_archive$claim_id, float_rewrite$claim_id))

counterparts <- bind_rows(
  float_archive |>
    join_1to1(float_rewrite, "claim_id") |>
    mutate(evidence = "", notes = ""),
  computed
) |>
  select(claim_id, value_script, value_rewrite, evidence, notes)

# A counterpart keyed to a claim the article does not make is a mistyped label, and
# it would otherwise vanish in the join without ever reaching the ground truth.
stopifnot(all(counterparts$claim_id %in% published$claim_id))

# The build's own note on a claim leads; the extraction's note fills in where the
# build has none, which is how a claim the deposit cannot speak to says why.
gt <- published |>
  rename(extraction_notes = notes) |>
  join_1to1(counterparts, "claim_id", all_matched = FALSE) |>
  mutate(notes = if_else(is.na(notes) | notes == "", extraction_notes, notes)) |>
  select(-extraction_notes)

# Coverage of maintained/in_text_claims.R ----
# Every published claim must also be printed by in_text_claims.R, which recomputes
# it from the same pipeline outputs by a separate path. Every claim needs a block,
# not only the pipeline and descriptive ones: a definitional or structural claim has
# no pipeline counterpart by design, which is exactly why nothing else in this build
# would notice its absence. The extraction says so by marking every row
# needs_block, and in_text_claims.R's assert_claims() stops unless the claims it
# prints are exactly those rows.
stopifnot(all(published$needs_block == "TRUE"))

# Coverage of the ground truth. A pipeline claim with no computed counterpart, or a
# descriptive claim with no computed evidence, is the coverage failure this file
# exists to expose, so it stops the build rather than becoming an unverifiable row.
uncovered <- gt |>
  filter((claim_type == "pipeline" & is.na(value_rewrite)) |
           (claim_type == "descriptive" & (is.na(evidence) | evidence == "")))

if (nrow(uncovered) > 0) {
  print(uncovered |> select(claim_id, claim_type, value_paper), n = Inf, width = 200)
  stop(str_glue("{nrow(uncovered)} published claim(s) have no computed counterpart."))
}

# The pipeline's own checks on the wordless floats ----
# These are not published claims: the four figures print no numbers, so nothing on
# the page can be compared against them. What can be checked about them is checked
# here, and the checks that must hold are assertions rather than rows.
stopifnot(
  plotted_gap(f1, t3) == 0,
  plotted_gap(f2, t6) == 0,
  a2("Cells defined in one grid and not the other") == 0,
  a2("Maximum absolute difference from the deposited grid") < 1e-12,
  nrow(fa1) == spec("Panels") * spec("Grid cells per panel")
)

internal <- tribble(
  ~prefix, ~claim, ~claim_type, ~value_script, ~value_rewrite, ~notes,
  "figure_1", "Plotted estimates depart from the Table 3 estimates by at most",
    "pipeline", NA, plotted_gap(f1, t3),
    "The figure prints no numbers. It is drawn from the Table 3 output file, and this row measures that it is",
  "figure_1", "Estimates plotted", "structural", NA, nrow(f1),
    "Five items by three estimators",
  "figure_2", "Plotted estimates depart from the Table 6 estimates by at most",
    "pipeline", NA, plotted_gap(f2, t6),
    "The figure prints no numbers. It is drawn from the Table 6 output file, and this row measures that it is",
  "figure_2", "Estimates plotted", "structural", NA, nrow(f2),
    "Five items by three estimators",
  "figure_a1", "Grid cells simulated", "structural", NA, nrow(fa1),
    str_glue("{spec('Panels')} panels at {spec('Simulations per grid cell')} simulated experiments per cell"),
  "figure_a1", "Power moved by re-running under the pre-3.6 sampler, at most",
    "pipeline", NA, max(abs(sampler$difference)),
    "The deposit sets no seed, so no sampler reproduces the published figure cell for cell. This row measures what the sampler change alone is worth",
  "figure_a2", "Cells the deposited script and the rewrite both define",
    "pipeline", a2("Cells where both grids are defined"),
    a2("Cells where both grids are defined"),
    "The figure prints no numbers, so it is verified against a run of the deposited script rather than against the page",
  "figure_a2", "Cells one grid defines and the other does not",
    "pipeline", a2("Cells defined in one grid and not the other"),
    a2("Cells defined in one grid and not the other"),
    str_glue("{a2('Cells undefined in both grids')} cells are undefined in both: ",
             "power.prop.test returns NaN where the two rates are equal at 0 or at 1"),
  "figure_a2", "Maximum absolute difference from the deposited grid",
    "pipeline", NA, a2("Maximum absolute difference from the deposited grid"), ""
) |>
  mutate(claim_id = as.character(str_glue("{prefix} :: {claim}")),
         location = prefix |> str_replace("^figure_a", "Figure A") |> str_replace("^figure_", "Figure "),
         evidence = "") |>
  select(-prefix)

# Agreement at the precision the article prints ----
# digits is the extraction's own precision for each claim, so the basis of every
# verdict is written into the committed file beside the verdict. A row the build adds
# for a figure has no extraction row and no printed value, so it is a pipeline or
# structural check whose precision is that of no printed string.
gt <- bind_rows(gt, internal) |>
  mutate(
    paper_id = "aronow_etal_2015",
    value_script_printed = printed_as_paper(value_script, digits),
    value_rewrite_printed = printed_as_paper(value_rewrite, digits),
    match = if_else(is.na(value_script_printed), NA, value_script_printed == value_paper),
    match_rewrite = if_else(is.na(value_rewrite_printed), NA, value_rewrite_printed == value_paper),
    # A value exactly half a printed digit away from the page rounds either way, so
    # its verdict turns on the tie rather than on the estimate. Flagged in the note
    # rather than resolved: an appendix power cell sits here and no rounding rule
    # settles it.
    on_rounding_boundary = abs(abs(value_rewrite - parse_number(value_paper)) -
                                 0.5 * 10^(-digits)) < 1e-9
  )

# defect_locus is recorded on every row where the rewrite and the article disagree.
# There is no default value: a disagreement this script has not classified stops the
# build, because "unresolved" typed automatically is not a finding.
gt <- gt |>
  mutate(defect_locus = case_when(
    is.na(match_rewrite) | match_rewrite ~ NA_character_,
    str_detect(claim, "^Power at (200|800) admitters") ~ "archive"
  ))

# The verdict clause of a note is generated from the same comparison that sets the
# verdict, so the two cannot drift apart. The typed part of the note says why. The
# computed evidence for a descriptive claim leads its note, and a value on a rounding
# boundary says so.
gt <- gt |>
  mutate(
    notes = replace_na(notes, ""),
    notes = if_else(
      !is.na(match_rewrite) & !match_rewrite,
      str_trim(str_glue("The rewrite prints {value_rewrite_printed} where the page prints {value_paper}. {notes}")),
      notes
    ),
    notes = if_else(
      replace_na(on_rounding_boundary, FALSE),
      str_trim(str_glue("{notes} The rewrite's value sits exactly half a printed digit from the page, so it rounds either way.")),
      notes
    ),
    notes = case_when(
      is.na(evidence) | evidence == "" ~ notes,
      notes == "" ~ str_c(evidence, "."),
      .default = str_c(evidence, ". ", notes)
    ),
    notes = na_if(notes, "")
  )

contradicts <- str_detect(replace_na(gt$notes, ""),
                          regex("disagree|does not match|mismatch|differs from",
                                ignore_case = TRUE))
stopifnot(
  !any(gt$match_rewrite & contradicts, na.rm = TRUE),
  !any(is.na(gt$defect_locus) & !gt$match_rewrite, na.rm = TRUE)
)

# Disposition: what became of each defect ----
# corrected_here is computed from the errata spine and never typed: a row is
# corrected here exactly when an entry's claim_ids names it. Every other judgment
# is taken from what the report already says happened, keyed the way defect_locus is
# keyed; a defect nobody has judged stays NA.
errata <- read_csv(here::here("errata_entries.csv"), col_types = cols(.default = col_character()))
cited_claim_ids <- errata$claim_ids |>
  na.omit() |>
  str_split(";") |>
  unlist() |>
  str_trim() |>
  discard(\(x) x == "")
stopifnot(all(cited_claim_ids %in% gt$claim_id))

disposition_judgments <- tribble(
  ~pattern, ~judgment, ~disposition_reason,
  "^Power at (200|800) admitters", "documented_only",
    "The report documents that the deposit sets no seed, so the published Figure A1 is one unlabelled draw and these readings are right to the precision they can be made at; the rewrite seeds every cell and no erratum is issued."
)

judgment_for <- function(key, column) {
  hit <- disposition_judgments[[column]][map_lgl(disposition_judgments$pattern,
                                                 \(pattern) str_detect(key, pattern))]
  if (length(hit) == 0) NA_character_ else hit[1]
}

gt <- gt |>
  mutate(
    disposition = case_when(
      is.na(defect_locus) ~ NA_character_,
      claim_id %in% cited_claim_ids ~ "corrected_here",
      .default = map_chr(claim, judgment_for, column = "judgment")
    ),
    disposition_reason = if_else(
      !is.na(disposition) & disposition != "corrected_here",
      map_chr(claim, judgment_for, column = "disposition_reason"),
      NA_character_
    )
  )

undisposed <- gt |> filter(defect_locus == "paper_internal", is.na(disposition))
if (nrow(undisposed) > 0) {
  print(undisposed |> select(claim_id, location, claim), n = nrow(undisposed))
  stop(str_glue("{nrow(undisposed)} paper_internal rows carry no disposition."))
}
print(gt |> filter(!is.na(defect_locus)) |> count(defect_locus, disposition))

# Coverage of the published float list ----
# Enumerated from the article and the online supplement themselves rather than from
# what the pipeline happens to produce, so that a float nothing covers is a finding
# rather than a silence. Coverage is a gate: a published float with no row stops the
# build unless it is named below with the reason it has nothing to reproduce.
#
# The article prints its own Appendix A.1 as a Table A1 giving the wording of every
# list question and every direct question. It states no quantity. The Table A1 meant
# everywhere else here is the online supplement's factorial comparison, so the
# article's is labelled with where it is printed.
article_table_a1 <- "Table A1 (article, Appendix A.1)"

published_floats <- c(
  str_c("Table ", 1:8), "Figure 1", "Figure 2", article_table_a1,
  str_c("Table A", 1:8), "Figure A1", "Figure A2"
)

floats_without_values <- article_table_a1

float_of <- function(location) str_remove(location, " note$")

covered_floats <- gt$location |>
  float_of() |>
  keep(\(x) str_detect(x, "^(Table|Figure) ")) |>
  unique()

stopifnot(setequal(published_floats, union(covered_floats, floats_without_values)))

# Float coverage ----
# One row per published float. A table's published_numbers counts the numbers the
# transcription records on its face, its note included; covered counts those the
# build compares, and the two reproduced columns count those each pipeline matches.
# A figure prints no numbers, so what it carries is the count of quantities it plots,
# reproduced when the rewrite's plotted values are verified against their source.
table_counts <- gt |>
  mutate(float = float_of(location)) |>
  filter(str_starts(float, "Table ")) |>
  summarize(
    published_numbers = sum(!is.na(value_paper)),
    covered = sum(!is.na(match_rewrite)),
    reproduced_by_rewrite = sum(match_rewrite, na.rm = TRUE),
    reproduced_by_archive = sum(match, na.rm = TRUE),
    .by = float
  )

figure_counts <- tribble(
  ~float, ~plotted, ~plotted_reproduced, ~note,
  "Figure 1", nrow(f1), if (plotted_gap(f1, t3) == 0) nrow(f1) else 0L,
    "Prints no numbers on its face; plots the five Table 3 items under three estimators, drawn from the Table 3 output.",
  "Figure 2", nrow(f2), if (plotted_gap(f2, t6) == 0) nrow(f2) else 0L,
    "Prints no numbers on its face; plots the five Table 6 items under three estimators, drawn from the Table 6 output.",
  "Figure A1", nrow(fa1), NA_integer_,
    "Prints no numbers on its face; plots a simulated power grid the deposit drew without a seed, so no run reproduces it cell for cell and plotted_reproduced is NA.",
  "Figure A2", as.integer(a2("Cells compared with the deposited grid")),
    as.integer(a2("Cells where both grids are defined") + a2("Cells undefined in both grids")),
    "Prints no numbers on its face; every grid cell agrees with a run of the deposited script, counting the cells undefined in both."
)

float_coverage <- tibble(float = published_floats) |>
  left_join(table_counts, by = "float") |>
  left_join(figure_counts, by = "float") |>
  mutate(
    across(c(published_numbers, covered, reproduced_by_rewrite, reproduced_by_archive),
           \(x) as.integer(replace_na(x, 0L))),
    plotted = as.integer(plotted),
    plotted_reproduced = as.integer(plotted_reproduced),
    note = if_else(float == article_table_a1,
                   "Prints the wording of every list question and every direct question; states no quantity.",
                   note)
  ) |>
  select(float, published_numbers, covered, reproduced_by_rewrite, reproduced_by_archive,
         plotted, plotted_reproduced, note)

stopifnot(
  nrow(float_coverage) == length(published_floats),
  with(filter(float_coverage, str_starts(float, "Table "), published_numbers > 0),
       all(covered == published_numbers))
)

write_csv(float_coverage, here::here("ground_truth", "float_coverage.csv"))
print(float_coverage, n = nrow(float_coverage), width = 200)

# The ground truth, in the canonical column order ----
# claim_type and digits come from the extraction; a row the build adds for a figure
# keeps the type it declares above. holds is NA throughout: the descriptive claims
# here are checked by printing the distribution they describe, not by a verdict.
gt <- gt |>
  arrange(match(claim_id, c(published$claim_id, internal$claim_id))) |>
  mutate(holds = NA) |>
  select(paper_id, claim_id, location, claim_type, claim, value_paper, digits,
         value_script, match, value_rewrite, match_rewrite, holds, defect_locus,
         disposition, disposition_reason, notes)

stopifnot(!anyNA(gt$claim_type), !anyNA(gt$location))

write_csv(gt, here::here("ground_truth", "aronow_etal_2015_ground_truth.csv"))

print(gt |>
        summarize(claims = n(),
                  archive_match = sum(match, na.rm = TRUE),
                  archive_fail = sum(!match, na.rm = TRUE),
                  rewrite_match = sum(match_rewrite, na.rm = TRUE),
                  rewrite_fail = sum(!match_rewrite, na.rm = TRUE),
                  unverifiable = sum(is.na(match_rewrite)),
                  .by = claim_type),
      n = Inf, width = 200)

print(gt |> filter(!match_rewrite | !match) |>
        select(claim_id, value_paper, value_rewrite, defect_locus, disposition),
      n = Inf, width = 200)
