# aronow_etal_2015/maintained/table_a6_rep_study_b_placebo_i.R
# Output: maintained/output/table_a6_rep_study_b_placebo_i.csv
# Depends on: maintained/data/rep_exp.rds, helpers.R
# Description: Table A6, Placebo Test I for Study B of the replication experiment.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_a6 <- read_rds(here::here("maintained", "data", "rep_exp.rds")) |>
  filter(listsfirst == 1) |>
  placebo_i_table()

write_csv(table_a6, here::here("maintained", "output", "table_a6_rep_study_b_placebo_i.csv"))

print(table_a6, width = Inf)
