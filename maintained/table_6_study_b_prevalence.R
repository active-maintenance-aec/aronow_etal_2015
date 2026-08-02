# aronow_etal_2015/maintained/table_6_study_b_prevalence.R
# Output: maintained/output/table_6_study_b_prevalence.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 6, the three estimates of prevalence for Study B of the main
#   experiment, where the list experiments were asked before the direct questions.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_6 <- read_rds(here::here("maintained", "data", "main_exp.rds")) |>
  filter(listsfirst == 1) |>
  prevalence_table()

write_csv(table_6, here::here("maintained", "output", "table_6_study_b_prevalence.csv"))

print(table_6, width = Inf)
