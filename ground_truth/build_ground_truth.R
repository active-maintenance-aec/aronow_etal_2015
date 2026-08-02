# aronow_etal_2015/ground_truth/build_ground_truth.R
# Output: ground_truth/aronow_etal_2015_ground_truth.csv
# Depends on: ground_truth/archive_values.csv (run_archive.R),
#             maintained/output/ (run run_all.R first)
# Description: Assemble the ground truth table. Every value_paper entry below was
#   typed from the published article and the online supplementary materials and is
#   used only as a comparison target; no published number is an input to any
#   computation here or anywhere in maintained/. value_script is read back from the
#   deposited scripts' own run and value_rewrite from maintained/output/, so neither
#   column can drift from the code it describes.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

items <- c("Nuclear Power", "Public Transportation", "Spanish-speaking",
           "Muslim Teachers", "CNN")

conditions <- c("Study A", "Study B", "List 1 T", "List 1 C", "List 2 T", "List 2 C",
                "List 3 T", "List 3 C", "List 4 T", "List 4 C", "List 5 T", "List 5 C")

balance_groups <- c("Study A Treat", "Study A Control", "Study B Treat", "Study B Control")

prevalence_cols <- c("Direct", "Direct SE", "Standard list", "Standard list SE",
                     "Combined", "Combined SE", "% reduction in sampling variance")
placebo_cols <- c("beta", "SE", "p-value", "n")
factorial_cols <- c("Direct difference", "Direct SE",
                    "Conventional list difference", "Conventional list SE",
                    "Combined list difference", "Combined list SE")

# value_paper is carried as the string the published page prints, never as a number,
# because a double does not record how many decimals were printed: 0.80 and 0.8 are
# the same double and would be compared at tolerances differing by a factor of ten.
# The tolerance is read off the string instead, as half of its last printed digit.
printed_tolerance <- function(value_paper) {
  decimals <- if_else(str_detect(value_paper, fixed(".")),
                      nchar(str_remove(value_paper, "^[^.]*\\.")),
                      0L)
  0.5 * 10^(-decimals)
}

published_block <- function(table_figure, rows, cols, values) {
  stopifnot(is.character(values), length(values) == length(rows) * length(cols))
  tibble(
    table_figure = table_figure,
    claim = as.character(str_glue("{rep(rows, each = length(cols))}: {rep(cols, times = length(rows))}")),
    value_paper = values
  )
}

# Table 1, from the article, p. 52 ----
# The article prints the upper block triangle only; the empty cells are structural.
table_1_published <- matrix(c(
  "500",   "0", "245", "255", "238", "262", "275", "225", "243", "257", "232", "268",
    "0", "514", "272", "242", "259", "255", "253", "261", "271", "243", "260", "254",
   NA,  NA, "517",   "0", "251", "266", "273", "244", "269", "248", "273", "244",
   NA,  NA,   "0", "497", "246", "251", "255", "242", "245", "252", "219", "278",
   NA,  NA,  NA,  NA, "497",   "0", "253", "244", "246", "251", "240", "257",
   NA,  NA,  NA,  NA,   "0", "517", "275", "242", "268", "249", "252", "265",
   NA,  NA,  NA,  NA,  NA,  NA, "528",   "0", "269", "259", "263", "265",
   NA,  NA,  NA,  NA,  NA,  NA,   "0", "486", "245", "241", "229", "257",
   NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA, "514",   "0", "256", "258",
   NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA,   "0", "500", "236", "264",
   NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA, "492",   "0",
   NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA,  NA,   "0", "522"
), nrow = 12, byrow = TRUE)

table_1_gt <- tibble(
  table_figure = "table_1",
  claim = as.character(str_glue("{rep(conditions, each = 12)} x {rep(conditions, times = 12)}")),
  value_paper = as.vector(t(table_1_published))
) |>
  drop_na(value_paper)

# Table 2, from the article, p. 53 ----
# The row labels are the levels as they appear in the deposited data, which the
# article renders with different capitalisation and dashes.
table_2_levels <- c(
  "18 to 24", "25 to 34", "35 to 44", "45 to 54", "55 to 64", "65 or over",
  "Female", "Male", "Prefer not to say -- Gender",
  "Liberal", "Moderate", "Conservative", "Haven't thought much about this",
  "Less than High School", "High School / GED", "Some College",
  "4-year College Degree", "Graduate School",
  "White, non Hispanic", "African-American", "Asian/Pacific Islander",
  "Hispanic", "Native American", "Other", "Prefer not to say -- Race"
)

table_2_gt <- bind_rows(
  published_block("table_2", table_2_levels, balance_groups, c(
    "24.49", "25.49", "23.53", "32.64",
    "40.82", "43.92", "41.18", "40.91",
    "20.00", "15.29", "17.28", "14.88",
     "8.16", "10.98", "10.66",  "6.20",
     "4.90",  "3.92",  "5.88",  "3.72",
     "1.63",  "0.39",  "1.47",  "1.65",
    "46.12", "47.45", "46.32", "42.98",
    "53.88", "52.16", "53.31", "57.02",
     "0.00",  "0.39",  "0.37",  "0.00",
    "50.61", "42.35", "50.37", "51.65",
    "28.16", "34.51", "26.84", "28.51",
    "18.37", "19.22", "20.59", "14.46",
     "2.86",  "3.92",  "2.21",  "5.37",
     "0.41",  "0.78",  "0.74",  "1.24",
    "11.02", "11.76", "10.66",  "7.44",
    "42.45", "42.75", "40.44", "40.91",
    "33.47", "33.73", "35.29", "36.36",
    "12.65", "10.98", "12.87", "14.05",
    "79.18", "77.65", "79.78", "80.17",
     "7.76", "10.98",  "6.62",  "4.55",
     "5.71",  "4.71",  "5.15",  "9.92",
     "4.90",  "3.92",  "6.25",  "4.13",
     "0.82",  "0.78",  "1.10",  "0.83",
     "1.22",  "1.18",  "1.10",  "0.41",
     "0.41",  "0.78",  "0.00",  "0.00"
  )),
  published_block("table_2", "n", balance_groups, c("245", "255", "272", "242"))
)

# Tables 3 to 8, from the article, pp. 54 to 57 ----
analysis_gt <- bind_rows(
  published_block("table_3", items, prevalence_cols, c(
    "0.656", "0.021", "0.748", "0.084", "0.666", "0.048", "67.1",
    "0.538", "0.022", "0.513", "0.072", "0.627", "0.049", "54.0",
    "0.102", "0.014", "0.035", "0.079", "0.042", "0.074", "14.0",
    "0.110", "0.014", "0.166", "0.081", "0.187", "0.074", "15.3",
    "0.444", "0.022", "0.338", "0.105", "0.533", "0.070", "54.9"
  )),

  published_block("table_4", items, placebo_cols, c(
    "1.054", "0.095", "0.568", "328",
    "0.790", "0.091", "0.021", "269",
    "0.848", "0.279", "0.585",  "51",
    "1.008", "0.237", "0.973",  "55",
    "0.696", "0.143", "0.034", "222"
  )),

  published_block("table_5", items, placebo_cols, c(
     "0.066", "0.042", "0.118", "500",
    "-0.000", "0.045", "0.994", "500",
     "0.016", "0.027", "0.560", "500",
    "-0.030", "0.028", "0.285", "500",
    "-0.056", "0.045", "0.206", "500"
  )),

  published_block("table_6", items, prevalence_cols, c(
    "0.603", "0.022", "0.499", "0.089", "0.624", "0.052", "66.0",
    "0.539", "0.022", "0.578", "0.073", "0.608", "0.051", "51.9",
    "0.113", "0.014", "0.144", "0.083", "0.149", "0.076", "16.4",
    "0.103", "0.013", "0.107", "0.083", "0.123", "0.074", "20.1",
    "0.496", "0.022", "0.645", "0.101", "0.587", "0.064", "60.2"
  )),

  published_block("table_7", items, placebo_cols, c(
    "0.881", "0.113", "0.294", "310",
    "0.913", "0.091", "0.339", "277",
    "0.767", "0.229", "0.309",  "58",
    "0.700", "0.285", "0.293",  "53",
    "0.847", "0.135", "0.256", "255"
  )),

  published_block("table_8", items, placebo_cols, c(
    "-0.086", "0.043", "0.045", "514",
     "0.034", "0.044", "0.434", "514",
     "0.027", "0.028", "0.337", "514",
     "0.016", "0.027", "0.549", "514",
     "0.132", "0.044", "0.003", "514"
  )),

  # Tables A1 to A8, from the online supplementary materials, pp. 4 to 7 ----
  published_block("table_a1", items, factorial_cols, c(
     "0.053", "0.030",  "0.249", "0.122",  "0.042", "0.071",
    "-0.001", "0.031", "-0.064", "0.103",  "0.019", "0.071",
    "-0.011", "0.019", "-0.109", "0.115", "-0.106", "0.106",
     "0.007", "0.019",  "0.060", "0.116",  "0.064", "0.105",
    "-0.052", "0.031", "-0.307", "0.146", "-0.054", "0.095"
  )),

  published_block("table_a2", items, prevalence_cols, c(
    "0.646", "0.021", "0.575", "0.086", "0.647", "0.049", "67.556",
    "0.555", "0.022", "0.635", "0.073", "0.653", "0.048", "56.677",
    "0.061", "0.011", "0.118", "0.078", "0.104", "0.073", "12.079",
    "0.083", "0.012", "0.034", "0.078", "0.036", "0.072", "14.671",
    "0.407", "0.022", "0.256", "0.100", "0.298", "0.074", "45.350"
  )),

  published_block("table_a3", items, placebo_cols, c(
    "0.938", "0.104", "0.549", "327",
    "0.949", "0.089", "0.566", "281",
    "0.816", "0.311", "0.554",  "31",
    "1.048", "0.297", "0.872",  "42",
    "0.711", "0.133", "0.029", "206"
  )),

  published_block("table_a4", items, placebo_cols, c(
    "-0.059", "0.042", "0.166", "506",
     "0.017", "0.044", "0.699", "506",
     "0.031", "0.021", "0.154", "506",
    "-0.009", "0.025", "0.729", "506",
     "0.075", "0.044", "0.087", "506"
  )),

  published_block("table_a5", items, prevalence_cols, c(
    "0.591", "0.022", "0.364", "0.087", "0.521", "0.054", "61.053",
    "0.520", "0.022", "0.602", "0.073", "0.672", "0.049", "54.990",
    "0.099", "0.013", "0.025", "0.079", "0.094", "0.074", "11.822",
    "0.103", "0.014", "0.195", "0.082", "0.164", "0.074", "18.580",
    "0.457", "0.022", "0.586", "0.107", "0.604", "0.074", "51.321"
  )),

  published_block("table_a6", items, placebo_cols, c(
    "0.739", "0.110", "0.018", "299",
    "0.795", "0.097", "0.034", "263",
    "0.301", "0.262", "0.008",  "50",
    "1.005", "0.297", "0.987",  "52",
    "0.759", "0.141", "0.087", "231"
  )),

  published_block("table_a7", items, placebo_cols, c(
    "-0.003", "0.044", "0.941", "506",
     "0.075", "0.044", "0.094", "506",
    "-0.001", "0.027", "0.974", "506",
     "0.039", "0.027", "0.141", "506",
     "0.092", "0.044", "0.038", "506"
  )),

  published_block("table_a8", items, factorial_cols, c(
     "0.055", "0.031",  "0.210", "0.123",  "0.127", "0.073",
     "0.036", "0.031",  "0.032", "0.103", "-0.019", "0.068",
    "-0.038", "0.017",  "0.093", "0.111",  "0.010", "0.104",
    "-0.020", "0.018", "-0.161", "0.113", "-0.128", "0.104",
    "-0.049", "0.031", "-0.330", "0.146", "-0.306", "0.105"
  ))
)

published <- bind_rows(table_1_gt, table_2_gt, analysis_gt)

# The rewrite's own values, read back out of maintained/output/ ----
rewrite_analysis <- function(table_figure, file, cols) {
  out(file) |>
    pivot_longer(-item, names_to = "column", values_to = "value_rewrite") |>
    transmute(
      table_figure = table_figure,
      claim = as.character(str_glue("{item}: {rep(cols, times = 5)}")),
      value_rewrite
    )
}

analysis_files <- tribble(
  ~table_figure, ~file, ~cols,
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
  transmute(table_figure = "table_1",
            claim = as.character(str_glue("{condition} x {crossed_with}")),
            value_rewrite) |>
  drop_na(value_rewrite)

rewrite_table_2 <- out("table_2_covariate_balance.csv") |>
  pivot_longer(all_of(balance_groups), names_to = "group", values_to = "value_rewrite") |>
  transmute(table_figure = "table_2",
            claim = as.character(str_glue("{level}: {group}")),
            value_rewrite)

rewrite <- bind_rows(
  rewrite_table_1,
  rewrite_table_2,
  pmap(analysis_files, rewrite_analysis) |> list_rbind()
)

archive <- read_csv(here::here("ground_truth", "archive_values.csv"), show_col_types = FALSE)

arc <- function(table_figure, claim) {
  value <- archive$value_script[archive$table_figure == table_figure & archive$claim == claim]
  stopifnot(length(value) == 1)
  value
}

# Both joins run on (table_figure, claim), which is asserted unique on all three
# sides first. A duplicated key on either right-hand side would silently multiply
# rows, and a key present on neither would leave a column of NA that reads as
# "unverifiable" rather than as the wiring fault it is, so the row count is
# asserted and so is the absence of NA.
unique_key <- function(d) nrow(distinct(d, table_figure, claim)) == nrow(d)
stopifnot(unique_key(published), unique_key(archive), unique_key(rewrite))

tables_gt <- published |>
  left_join(archive, by = c("table_figure", "claim")) |>
  left_join(rewrite, by = c("table_figure", "claim"))

stopifnot(
  nrow(tables_gt) == nrow(published),
  !anyNA(tables_gt$value_script),
  !anyNA(tables_gt$value_rewrite)
)

# In-text claims and the four figures ----
# Every value_rewrite below is read out of maintained/output/ rather than typed.
sizes <- out("text_sample_sizes.csv")
main_sizes <- filter(sizes, experiment == "main")
rep_sizes <- filter(sizes, experiment == "replication")

t3 <- out("table_3_study_a_prevalence.csv")
t4 <- out("table_4_study_a_placebo_i.csv")
t8 <- out("table_8_study_b_placebo_ii.csv")
ta1 <- out("table_a1_factorial.csv")

f1 <- out("figure_1_study_a_prevalence.csv")
f2 <- out("figure_2_study_b_prevalence.csv")
t6 <- out("table_6_study_b_prevalence.csv")
fa1 <- out("figure_a1_placebo_i_power.csv")
a2_check <- out("text_figure_a2_archive_grid.csv")
sampler <- out("text_placebo_i_sampler.csv")

# Figures 1 and 2 plot the Table 3 and Table 6 estimates. The check is that the
# plotted numbers are those numbers, measured rather than asserted. The two frames
# are joined on (item, estimator) rather than sorted into alignment, and the join
# asserts its row count, so a renamed estimator or a dropped item stops the build
# instead of quietly comparing the wrong pairs.
plotted_gap <- function(fig, tab) {
  long <- tab |>
    pivot_longer(c(direct, conv, combined), names_to = "estimator", values_to = "est")
  drawn <- fig |>
    mutate(estimator = recode_values(as.character(estimator),
                                     "Direct Estimate" ~ "direct",
                                     "Standard List Estimate" ~ "conv",
                                     "Combined Estimate" ~ "combined")) |>
    select(item, estimator, est_plotted = est)
  joined <- inner_join(long, drawn, by = c("item", "estimator"))
  stopifnot(nrow(joined) == nrow(long), nrow(long) == nrow(fig))
  max(abs(joined$est - joined$est_plotted))
}

power_at <- function(panel_name, n_admitters, proportion) {
  fa1$power[fa1$panel == panel_name & fa1$admitter_n == n_admitters &
              abs(fa1$prop - proportion) < 1e-9]
}

a2 <- function(claim) {
  value <- a2_check$value[a2_check$claim == claim]
  stopifnot(length(value) == 1)
  value
}

# The wordless floats have nothing on the page to compare against, so they carry a
# blank value_paper and an NA verdict. What can be checked about them is checked
# here instead, as a gate: a figure that stopped being drawn from the table it
# illustrates, or a power grid that stopped agreeing with the deposit's, stops the
# build rather than turning into a row nobody reads.
stopifnot(
  plotted_gap(f1, t3) == 0,
  plotted_gap(f2, t6) == 0,
  a2("Cells defined in one grid and not the other") == 0,
  a2("Maximum absolute difference from the deposited grid") < 1e-12,
  nrow(fa1) == 4 * 1919
)

# The Monte Carlo standard error of a single Figure A1 cell at power 0.8, which is
# what the appendix's "80% power" claim can be established to.
mc_se_at_80 <- sqrt(0.8 * 0.2 / 1000)

extras <- tribble(
  ~table_figure, ~claim, ~value_paper, ~tolerance, ~value_script, ~value_rewrite, ~notes,

  "text, p. 52", "Subjects recruited for the main experiment", "1023", NA,
    NA, main_sizes$n_deposited, "",
  "text, p. 52", "Subjects excluded from the main experiment", "9", NA,
    NA, main_sizes$n_dropped,
    "The article gives this as two failed attention checks plus seven incomplete responses; the deposited data cannot separate the two",
  "text, p. 52", "Complete cases in the main experiment", "1014", NA,
    NA, main_sizes$n_complete, "",
  "table_3 note", "Study A sample size", "500", NA,
    arc("table_1", "Study A x Study A"), main_sizes$n_study_a, "",
  "table_6 note", "Study B sample size", "514", NA,
    arc("table_1", "Study B x Study B"), main_sizes$n_study_b, "",
  "text, p. 54", "Smallest reduction in sampling variance, Study A (%)", "14", NA,
    min(archive$value_script[archive$table_figure == "table_3" &
                               str_detect(archive$claim, "% reduction")]),
    min(t3$var_reduc),
    "The article gives the range as 14 to 67 percent",
  "text, p. 54", "Largest reduction in sampling variance, Study A (%)", "67", NA,
    max(archive$value_script[archive$table_figure == "table_3" &
                               str_detect(archive$claim, "% reduction")]),
    max(t3$var_reduc), "",
  "text, p. 54", "Placebo Test I p-value quoted for Public Transportation", "0.02", NA,
    arc("table_4", "Public Transportation: p-value"),
    t4$p_value[t4$item == "Public Transportation"], "",
  "text, p. 54", "Placebo Test I p-value quoted for CNN", "0.03", NA,
    arc("table_4", "CNN: p-value"), t4$p_value[t4$item == "CNN"], "",
  "text, p. 57", "Effect of the treatment list on the nuclear power direct question, Study B (pp)",
    "8.6", NA, abs(100 * arc("table_8", "Nuclear Power: beta")),
    abs(100 * t8$beta[t8$item == "Nuclear Power"]),
    "The article gives the magnitude and states the direction in words: treated subjects were less likely to declare support",
  "text, p. 57", "Effect of the treatment list on the CNN direct question, Study B (pp)",
    "13.2", NA, abs(100 * arc("table_8", "CNN: beta")),
    abs(100 * t8$beta[t8$item == "CNN"]),
    "The article gives the magnitude and states the direction in words: treated subjects were more likely to report watching CNN",
  "appendix E text", "Order effect on the conventional list estimate for nuclear power (pp)",
    "24.9", NA, 100 * arc("table_a1", "Nuclear Power: Conventional list difference"),
    100 * ta1$conv_diff[ta1$item == "Nuclear Power"], "",
  "appendix E text", "Order effect on the conventional list estimate for CNN (pp)",
    "30.7", NA, abs(100 * arc("table_a1", "CNN: Conventional list difference")),
    abs(100 * ta1$conv_diff[ta1$item == "CNN"]),
    "The appendix gives the magnitude and states the direction in words: lower when the direct questions are asked first",
  "appendix F text", "Users who started the replication survey", "1019", NA,
    NA, rep_sizes$n_deposited, "",
  "appendix F text", "Excluded from the replication", "7", NA,
    NA, rep_sizes$n_dropped, "",
  "appendix F text", "Complete cases in the replication", "1012", NA,
    NA, rep_sizes$n_complete, "",
  "appendix F text", "Replication Study A sample size", "506", NA,
    NA, rep_sizes$n_study_a, "",
  "appendix F text", "Replication Study B sample size", "506", NA,
    NA, rep_sizes$n_study_b, "",

  "figure_1", "Plotted estimates depart from the Table 3 estimates by at most",
    NA, NA, NA, plotted_gap(f1, t3),
    "The figure prints no numbers. It is drawn from the Table 3 output file, and this row measures that it is",
  "figure_1", "Estimates plotted", NA, NA, NA, nrow(f1),
    "Five items by three estimators",
  "figure_2", "Plotted estimates depart from the Table 6 estimates by at most",
    NA, NA, NA, plotted_gap(f2, t6),
    "The figure prints no numbers. It is drawn from the Table 6 output file, and this row measures that it is",
  "figure_2", "Estimates plotted", NA, NA, NA, nrow(f2),
    "Five items by three estimators",

  "figure_a1", "Grid cells simulated", NA, NA, NA, nrow(fa1),
    "Four panels of 1,919 cells, at 1,000 simulated experiments each",
  "appendix C text", "Grid cells per panel of Figure A1", "1919", NA,
    NA, nrow(fa1) / 4,
    "The appendix prints the sequences rather than their product: 100 to 1000 in steps of 50 by 0 to 1 in steps of 0.01",
  "appendix C text", "Power at 800 admitters and 20 percent false confessors", "0.80", NA,
    NA, power_at("no false confessions", 800, 0.20),
    str_glue("The appendix prints this as 80% and hedges the settings as approximate. ",
             "A cell is 1,000 simulated experiments, so its standard error at power 0.8 ",
             "is {round(mc_se_at_80, 3)}, wider than the precision the appendix prints to"),
  "appendix C text", "Power at 800 admitters and 20 percent liars", "0.80", NA,
    NA, power_at("no liars", 800, 0.20), "",
  "appendix C text", "Power at 800 admitters and 20 percent design affected", "0.80", NA,
    NA, power_at("no design effects", 800, 0.20), "",
  "figure_a1", "Power moved by re-running under the pre-3.6 sampler, at most",
    NA, NA, NA, max(abs(sampler$difference)),
    "The deposit sets no seed, so no sampler reproduces the published figure cell for cell. This row measures what the sampler change alone is worth against a simulation error of 0.016 at power 0.5",

  "figure_a2", "Cells the deposited script and the rewrite both define",
    NA, NA, a2("Cells where both grids are defined"),
    a2("Cells where both grids are defined"),
    "The figure prints no numbers, so it is verified against a run of the deposited script rather than against the page",
  "figure_a2", "Cells one grid defines and the other does not",
    NA, NA, a2("Cells defined in one grid and not the other"),
    a2("Cells defined in one grid and not the other"),
    "Eight cells are undefined in both: power.prop.test returns NaN where the two rates are equal at 0 or at 1",
  "figure_a2", "Maximum absolute difference from the deposited grid",
    NA, NA, NA, a2("Maximum absolute difference from the deposited grid"), ""
)

# Agreement at the precision the article prints ----
# tolerance is half of the last digit value_paper prints, unless the row overrides
# it, and the column is written out so that the basis of every verdict is visible
# in the committed file rather than buried in this script.
agrees <- function(value, target, tolerance) {
  case_when(
    is.na(value) | is.na(target) ~ NA_real_,
    abs(value - target) <= tolerance ~ 1,
    .default = 0
  )
}

gt <- bind_rows(
  tables_gt |> mutate(tolerance = NA_real_, notes = ""),
  extras
) |>
  mutate(
    paper_id = "aronow_etal_2015",
    tolerance = if_else(is.na(tolerance), printed_tolerance(value_paper), tolerance),
    value_paper_numeric = parse_number(value_paper),
    match = agrees(value_script, value_paper_numeric, tolerance),
    match_rewrite = agrees(value_rewrite, value_paper_numeric, tolerance)
  )

# defect_locus is recorded on every row where the rewrite and the article disagree.
# The three power rows are the only ones: the appendix reads 80% power off an
# unseeded Monte Carlo whose cell standard error is wider than one printed digit,
# so the deposit cannot establish the claim to the precision it is stated at.
gt <- gt |>
  mutate(defect_locus = case_when(
    is.na(match_rewrite) | match_rewrite == 1 ~ NA_character_,
    str_starts(claim, "Power at 800 admitters") ~ "archive",
    .default = "unresolved"
  ))

# A note may not contradict its own row's verdict.
contradicts <- str_detect(gt$notes,
                          regex("disagree|does not match|mismatch|differs from",
                                ignore_case = TRUE))
stopifnot(
  !any(gt$match_rewrite == 1 & contradicts, na.rm = TRUE),
  !any(is.na(gt$defect_locus) & gt$match_rewrite == 0, na.rm = TRUE)
)

gt <- gt |>
  select(paper_id, table_figure, claim, value_script, value_paper, match,
         value_rewrite, match_rewrite, defect_locus, notes, tolerance)

write_csv(gt, here::here("ground_truth", "aronow_etal_2015_ground_truth.csv"))

print(gt |>
        summarize(claims = n(),
                  archive_match = sum(match == 1, na.rm = TRUE),
                  archive_fail = sum(match == 0, na.rm = TRUE),
                  rewrite_match = sum(match_rewrite == 1, na.rm = TRUE),
                  rewrite_fail = sum(match_rewrite == 0, na.rm = TRUE),
                  unverifiable = sum(is.na(match_rewrite)),
                  .by = table_figure),
      n = Inf, width = 200)

print(gt |> filter(match_rewrite == 0 | match == 0), n = Inf, width = 200)
