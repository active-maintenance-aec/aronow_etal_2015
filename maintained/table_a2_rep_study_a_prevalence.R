# aronow_etal_2015/maintained/table_a2_rep_study_a_prevalence.R
# Output: maintained/output/table_a2_rep_study_a_prevalence.csv
# Depends on: maintained/data/rep_exp.rds, helpers.R
# Description: Table A2, the three estimates of prevalence for Study A of the replication
#   experiment.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_a2 <- read_rds(here::here("maintained", "data", "rep_exp.rds")) |>
  filter(listsfirst == 0) |>
  prevalence_table()

write_csv(table_a2, here::here("maintained", "output", "table_a2_rep_study_a_prevalence.csv"))

print(table_a2, width = Inf)
