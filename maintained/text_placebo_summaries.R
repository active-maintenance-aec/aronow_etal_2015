# aronow_etal_2015/maintained/text_placebo_summaries.R
# Output: maintained/output/text_placebo_summaries.csv
#         maintained/output/text_placebo_joint_tests.csv
# Depends on: the eight placebo test output CSVs, helpers.R
# Description: The counts and joint tests the article states in prose rather than
#   in a table. Both placebo tests are reported item by item in Tables 4, 5, 7, 8,
#   A3, A4, A6 and A7; the article then says how many of them reject, in the
#   Results, in the Discussion, and again in Appendix F, and reports a joint test
#   of Placebo Test I by Fisher's method whose value it never prints. This script
#   reads those tables back and computes both, so that every one of those prose
#   sentences has something to be checked against.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

placebo_files <- tribble(
  ~experiment, ~study, ~test, ~file,
  "main", "Study A", "Placebo Test I", "table_4_study_a_placebo_i.csv",
  "main", "Study A", "Placebo Test II", "table_5_study_a_placebo_ii.csv",
  "main", "Study B", "Placebo Test I", "table_7_study_b_placebo_i.csv",
  "main", "Study B", "Placebo Test II", "table_8_study_b_placebo_ii.csv",
  "replication", "Study A", "Placebo Test I", "table_a3_rep_study_a_placebo_i.csv",
  "replication", "Study A", "Placebo Test II", "table_a4_rep_study_a_placebo_ii.csv",
  "replication", "Study B", "Placebo Test I", "table_a6_rep_study_b_placebo_i.csv",
  "replication", "Study B", "Placebo Test II", "table_a7_rep_study_b_placebo_ii.csv"
)

text_placebo_summaries <- placebo_files |>
  mutate(cells = map(file, \(f) read_csv(here::here("maintained", "output", f),
                                         show_col_types = FALSE))) |>
  unnest(cells) |>
  transmute(experiment, study, test, item, beta, se, p_value,
            rejects_at_05 = p_value < 0.05)

write_csv(text_placebo_summaries,
          here::here("maintained", "output", "text_placebo_summaries.csv"))

# Fisher's method ----
# The article reports a joint test of Placebo Test I "via Fisher's method" and
# prints no value for it, so the statistic is reconstructed here from the item
# level p-values it does print: -2 sum(log p) is chi-squared on twice as many
# degrees of freedom as there are tests, under independence.
text_placebo_joint_tests <- text_placebo_summaries |>
  summarize(
    tests = n(),
    chi_squared = -2 * sum(log(p_value)),
    df = 2 * n(),
    p_joint = pchisq(chi_squared, df = df, lower.tail = FALSE),
    n_rejects_at_05 = sum(rejects_at_05),
    .by = c(experiment, study, test)
  )

write_csv(text_placebo_joint_tests,
          here::here("maintained", "output", "text_placebo_joint_tests.csv"))

print(text_placebo_joint_tests, n = Inf, width = Inf)
