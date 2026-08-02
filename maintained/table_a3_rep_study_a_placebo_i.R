# aronow_etal_2015/maintained/table_a3_rep_study_a_placebo_i.R
# Output: maintained/output/table_a3_rep_study_a_placebo_i.csv
# Depends on: maintained/data/rep_exp.rds, helpers.R
# Description: Table A3, Placebo Test I for Study A of the replication experiment.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_a3 <- read_rds(here::here("maintained", "data", "rep_exp.rds")) |>
  filter(listsfirst == 0) |>
  placebo_i_table()

write_csv(table_a3, here::here("maintained", "output", "table_a3_rep_study_a_placebo_i.csv"))

print(table_a3, width = Inf)
