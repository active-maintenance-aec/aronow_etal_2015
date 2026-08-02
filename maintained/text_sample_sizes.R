# aronow_etal_2015/maintained/text_sample_sizes.R
# Output: maintained/output/text_sample_sizes.csv
# Depends on: original/ACCG_main_experiment.csv,
#             original/ACCG_replication_experiment.csv,
#             maintained/data/main_exp.rds, maintained/data/rep_exp.rds, helpers.R
# Description: The sample sizes the article and the online appendix state in prose:
#   how many subjects started each survey, how many were dropped for an incomplete
#   response or a failed attention check, and how many ended in each study arm.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

experiment_ns <- function(raw_file, clean_file, experiment) {
  raw <- read_csv(here::here("original", raw_file), show_col_types = FALSE)
  clean <- read_rds(here::here("maintained", "data", clean_file))
  tibble(
    experiment = experiment,
    n_deposited = nrow(raw),
    n_dropped = nrow(raw) - nrow(clean),
    n_complete = nrow(clean),
    n_study_a = sum(clean$listsfirst == 0),
    n_study_b = sum(clean$listsfirst == 1)
  )
}

text_sample_sizes <- bind_rows(
  experiment_ns("ACCG_main_experiment.csv", "main_exp.rds", "main"),
  experiment_ns("ACCG_replication_experiment.csv", "rep_exp.rds", "replication")
)

write_csv(text_sample_sizes, here::here("maintained", "output", "text_sample_sizes.csv"))

print(text_sample_sizes, width = Inf)
