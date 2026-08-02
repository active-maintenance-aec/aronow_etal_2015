# aronow_etal_2015/maintained/table_2_covariate_balance.R
# Output: maintained/output/table_2_covariate_balance.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 2, covariate balance across the treatment and control groups
#   of List Experiment 1 within each study. Entries are column percentages, and
#   the final row is the group size.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

main_exp <- read_rds(here::here("maintained", "data", "main_exp.rds"))

groups <- c("Study A Treat", "Study A Control", "Study B Treat", "Study B Control")

# The published table orders levels by substance rather than alphabetically, so
# the order is written out here and used to sort the assembled table.
level_order <- c(
  "18 to 24", "25 to 34", "35 to 44", "45 to 54", "55 to 64", "65 or over",
  "Female", "Male", "Prefer not to say -- Gender",
  "Liberal", "Moderate", "Conservative", "Haven't thought much about this",
  "Less than High School", "High School / GED", "Some College",
  "4-year College Degree", "Graduate School",
  "White, non Hispanic", "African-American", "Asian/Pacific Islander",
  "Hispanic", "Native American", "Other", "Prefer not to say -- Race"
)

balance_long <- main_exp |>
  mutate(
    group = case_when(
      listsfirst == 0 & list1treat == 1 ~ "Study A Treat",
      listsfirst == 0 & list1treat == 0 ~ "Study A Control",
      listsfirst == 1 & list1treat == 1 ~ "Study B Treat",
      listsfirst == 1 & list1treat == 0 ~ "Study B Control"
    )
  ) |>
  select(group, age, gender, ideology, education, race) |>
  pivot_longer(-group, names_to = "covariate", values_to = "level") |>
  count(group, covariate, level) |>
  mutate(percent = 100 * n / sum(n), .by = c(group, covariate)) |>
  select(-n)

percent_rows <- balance_long |>
  pivot_wider(names_from = group, values_from = percent) |>
  mutate(across(all_of(groups), \(x) replace_na(x, 0))) |>
  arrange(match(level, level_order)) |>
  select(covariate, level, all_of(groups))

n_row <- main_exp |>
  mutate(
    group = case_when(
      listsfirst == 0 & list1treat == 1 ~ "Study A Treat",
      listsfirst == 0 & list1treat == 0 ~ "Study A Control",
      listsfirst == 1 & list1treat == 1 ~ "Study B Treat",
      listsfirst == 1 & list1treat == 0 ~ "Study B Control"
    )
  ) |>
  count(group) |>
  pivot_wider(names_from = group, values_from = n) |>
  mutate(covariate = "n", level = "n", .before = everything()) |>
  select(covariate, level, all_of(groups))

table_2 <- bind_rows(percent_rows, n_row)

write_csv(table_2, here::here("maintained", "output", "table_2_covariate_balance.csv"))

print(table_2, n = Inf, width = Inf)
