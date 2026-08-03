# aronow_etal_2015/maintained/text_original_vs_replication.R
# Output: maintained/output/text_original_vs_replication.csv
# Depends on: the four prevalence output CSVs, helpers.R
# Description: The article says the estimates "vary somewhat between the original
#   experiments and the replication, but none of these differences are
#   significant". No published table reports that comparison: Tables A1 and A8
#   difference Study A against Study B within an experiment, not the main
#   experiment against the replication. This script builds the comparison the
#   sentence describes, differencing each estimate against its counterpart ten
#   months later. The two experiments are separate subjects, so the standard error
#   of a difference is the root of the sum of squared standard errors, which is
#   how the published factorial tables combine two independent estimates.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

prevalence_files <- tribble(
  ~experiment, ~study, ~file,
  "main", "Study A", "table_3_study_a_prevalence.csv",
  "main", "Study B", "table_6_study_b_prevalence.csv",
  "replication", "Study A", "table_a2_rep_study_a_prevalence.csv",
  "replication", "Study B", "table_a5_rep_study_b_prevalence.csv"
)

estimates <- prevalence_files |>
  mutate(cells = map(file, \(f) read_csv(here::here("maintained", "output", f),
                                         show_col_types = FALSE))) |>
  unnest(cells) |>
  pivot_longer(c(direct, conv, combined), names_to = "estimator", values_to = "est") |>
  mutate(se = case_when(
    estimator == "direct" ~ direct_se,
    estimator == "conv" ~ conv_se,
    estimator == "combined" ~ combined_se
  )) |>
  select(experiment, study, item, estimator, est, se)

text_original_vs_replication <- estimates |>
  pivot_wider(names_from = experiment, values_from = c(est, se)) |>
  mutate(
    difference = est_main - est_replication,
    se_difference = sqrt(se_main^2 + se_replication^2),
    p_value = 2 * pnorm(-abs(difference) / se_difference),
    rejects_at_05 = p_value < 0.05
  )

write_csv(text_original_vs_replication,
          here::here("maintained", "output", "text_original_vs_replication.csv"))

print(text_original_vs_replication |>
        summarize(comparisons = n(),
                  rejects = sum(rejects_at_05),
                  smallest_p = min(p_value),
                  .by = estimator),
      n = Inf, width = Inf)
