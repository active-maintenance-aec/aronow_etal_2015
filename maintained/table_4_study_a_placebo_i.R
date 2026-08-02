# aronow_etal_2015/maintained/table_4_study_a_placebo_i.R
# Output: maintained/output/table_4_study_a_placebo_i.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 4, Placebo Test I for Study A of the main experiment: among subjects
#   who answer "Yes" to the direct question, the list experiment difference in
#   means should equal one.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_4 <- read_rds(here::here("maintained", "data", "main_exp.rds")) |>
  filter(listsfirst == 0) |>
  placebo_i_table()

write_csv(table_4, here::here("maintained", "output", "table_4_study_a_placebo_i.csv"))

print(table_4, width = Inf)
