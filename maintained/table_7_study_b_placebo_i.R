# aronow_etal_2015/maintained/table_7_study_b_placebo_i.R
# Output: maintained/output/table_7_study_b_placebo_i.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 7, Placebo Test I for Study B of the main experiment.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_7 <- read_rds(here::here("maintained", "data", "main_exp.rds")) |>
  filter(listsfirst == 1) |>
  placebo_i_table()

write_csv(table_7, here::here("maintained", "output", "table_7_study_b_placebo_i.csv"))

print(table_7, width = Inf)
