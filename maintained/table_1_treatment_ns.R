# aronow_etal_2015/maintained/table_1_treatment_ns.R
# Output: maintained/output/table_1_treatment_ns.csv
# Depends on: maintained/data/main_exp.rds, helpers.R
# Description: Table 1, the number of subjects in each treatment condition of the
#   main experiment and in every pairwise crossing of conditions. The published
#   table shows only the upper triangle, so the lower triangle is left empty here.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

main_exp <- read_rds(here::here("maintained", "data", "main_exp.rds"))

# One indicator column per experimental condition, in the published column order:
# study assignment first, then treatment and control of each of the five lists.
condition_indicators <- main_exp |>
  transmute(
    `Study A` = as.integer(listsfirst == 0),
    `Study B` = as.integer(listsfirst == 1),
    `List 1 T` = as.integer(list1treat == 1),
    `List 1 C` = as.integer(list1treat == 0),
    `List 2 T` = as.integer(list2treat == 1),
    `List 2 C` = as.integer(list2treat == 0),
    `List 3 T` = as.integer(list3treat == 1),
    `List 3 C` = as.integer(list3treat == 0),
    `List 4 T` = as.integer(list4treat == 1),
    `List 4 C` = as.integer(list4treat == 0),
    `List 5 T` = as.integer(list5treat == 1),
    `List 5 C` = as.integer(list5treat == 0)
  )

# Crossing counts: cell (i, j) is the number of subjects in both condition i and
# condition j, which is exactly the matrix crossproduct of the indicators.
crossings <- crossprod(as.matrix(condition_indicators))

# The published table prints each 2 x 2 diagonal block in full and leaves
# everything below the block diagonal empty, so blanking is by block rather than
# by element: the (Study B, Study A) cell is printed, the (List 1 T, Study A)
# cell is not.
block <- rep(1:6, each = 2)
crossings[outer(block, block, `>`)] <- NA_integer_

table_1 <- as_tibble(crossings, rownames = "condition")

write_csv(table_1, here::here("maintained", "output", "table_1_treatment_ns.csv"))

print(table_1, n = Inf, width = Inf)
