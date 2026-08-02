# aronow_etal_2015/maintained/table_8_study_b_placebo_ii.R
# Output: maintained/output/table_8_study_b_placebo_ii.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 8, Placebo Test II for Study B of the main experiment. This is the test
#   the article reports failing for nuclear power and for CNN.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_8 <- read_rds(here::here("maintained", "data", "main_exp.rds")) |>
  filter(listsfirst == 1) |>
  placebo_ii_table()

write_csv(table_8, here::here("maintained", "output", "table_8_study_b_placebo_ii.csv"))

print(table_8, width = Inf)
