# aronow_etal_2015/maintained/table_5_study_a_placebo_ii.R
# Output: maintained/output/table_5_study_a_placebo_ii.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 5, Placebo Test II for Study A of the main experiment: the list
#   experiment treatment should not affect the direct question response.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_5 <- read_rds(here::here("maintained", "data", "main_exp.rds")) |>
  filter(listsfirst == 0) |>
  placebo_ii_table()

write_csv(table_5, here::here("maintained", "output", "table_5_study_a_placebo_ii.csv"))

print(table_5, width = Inf)
