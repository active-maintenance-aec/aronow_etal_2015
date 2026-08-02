# aronow_etal_2015/maintained/table_3_study_a_prevalence.R
# Output: maintained/output/table_3_study_a_prevalence.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 3, the direct question, standard list and combined list estimates of
#   prevalence for the five items in Study A of the main experiment, with the
#   percent reduction in sampling variance the combined estimator buys.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_3 <- read_rds(here::here("maintained", "data", "main_exp.rds")) |>
  filter(listsfirst == 0) |>
  prevalence_table()

write_csv(table_3, here::here("maintained", "output", "table_3_study_a_prevalence.csv"))

print(table_3, width = Inf)
