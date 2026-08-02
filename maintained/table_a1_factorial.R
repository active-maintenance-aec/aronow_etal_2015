# aronow_etal_2015/maintained/table_a1_factorial.R
# Output: maintained/output/table_a1_factorial.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table A1, the factorial comparison of the main experiment: Study A minus
#   Study B for each of the three estimators, with the standard error of the
#   difference.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_a1 <- read_rds(here::here("maintained", "data", "main_exp.rds")) |>
  factorial_table()

write_csv(table_a1, here::here("maintained", "output", "table_a1_factorial.csv"))

print(table_a1, width = Inf)
