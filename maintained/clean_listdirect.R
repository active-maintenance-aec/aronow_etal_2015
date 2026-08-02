# aronow_etal_2015/maintained/clean_listdirect.R
# Output: maintained/data/main_exp.rds
#         maintained/data/rep_exp.rds
# Depends on: original/ACCG_main_experiment.csv, original/ACCG_replication_experiment.csv
# Description: Reads both deposited datasets and applies the complete case
#   restriction the article describes, dropping subjects who left any of the five
#   direct questions or any of the five list counts blank.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

dir.create(here::here("maintained", "data"), showWarnings = FALSE)
dir.create(here::here("maintained", "output"), showWarnings = FALSE)

# Main experiment ----
# n = 1014 after dropping the nine incomplete cases.
main_exp <- read_csv(
  here::here("original", "ACCG_main_experiment.csv"),
  show_col_types = FALSE
) |>
  drop_na(direct1, direct2, direct3, direct4, direct5,
          list1N, list2N, list3N, list4N, list5N)

# Replication experiment ----
# n = 1012 after dropping the seven incomplete cases.
rep_exp <- read_csv(
  here::here("original", "ACCG_replication_experiment.csv"),
  show_col_types = FALSE
) |>
  drop_na(direct1, direct2, direct3, direct4, direct5,
          list1N, list2N, list3N, list4N, list5N)

write_rds(main_exp, here::here("maintained", "data", "main_exp.rds"))
write_rds(rep_exp, here::here("maintained", "data", "rep_exp.rds"))

print(tibble(
  dataset = c("main_exp", "rep_exp"),
  n = c(nrow(main_exp), nrow(rep_exp)),
  n_study_a = c(sum(main_exp$listsfirst == 0), sum(rep_exp$listsfirst == 0)),
  n_study_b = c(sum(main_exp$listsfirst == 1), sum(rep_exp$listsfirst == 1))
))
