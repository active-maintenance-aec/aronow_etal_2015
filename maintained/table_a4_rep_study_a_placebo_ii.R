# aronow_etal_2015/maintained/table_a4_rep_study_a_placebo_ii.R
# Output: maintained/output/table_a4_rep_study_a_placebo_ii.csv
# Depends on: maintained/data/rep_exp.rds, helpers.R
# Description: Table A4, Placebo Test II for Study A of the replication experiment. The
#   appendix mislabels this table as Placebo Test I.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

table_a4 <- read_rds(here::here("maintained", "data", "rep_exp.rds")) |>
  filter(listsfirst == 0) |>
  placebo_ii_table()

write_csv(table_a4, here::here("maintained", "output", "table_a4_rep_study_a_placebo_ii.csv"))

print(table_a4, width = Inf)
