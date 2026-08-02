# aronow_etal_2015/maintained/text_figure_a2_archive_grid.R
# Output: maintained/output/text_figure_a2_archive_grid.csv
# Depends on: maintained/output/figure_a2_placebo_ii_power.csv,
#             original/ACCG_list_placebo_II_power.R, helpers.R
# Description: Figure A2 prints no numbers, so it is verified against the deposit
#   rather than against the page. This script runs the deposited power script in a
#   scratch copy of the archive, captures the four grids it builds, and compares
#   them cell by cell with the grid the rewrite plots. It also measures what the
#   deposit's one inconsistency is worth: power.prop.test is called with
#   strict = TRUE in three panels and without it in the N = 100 panel, and strict
#   counts rejections in the wrong tail.
#
#   The join runs on the grid coordinates in hundredths rather than on the
#   proportions themselves. seq(0, 1, by = 0.01) does not survive a round trip
#   through a CSV, so a join on the proportions silently drops 792 of each panel's
#   10,201 cells and leaves a comparison that looks complete and is not.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

props <- seq(0, 1, by = 0.01)

# Run the deposited script ----
# The deposit is copied to a scratch directory and is never written to. Only the
# working directory call is patched, and the line it targets is asserted first, so
# a change to the deposit stops this script rather than being silently patched
# around. The script writes five PDFs beside itself, which is why it is run in the
# copy rather than in original/.
scratch <- file.path(tempdir(), "aronow_etal_2015_figure_a2")
unlink(scratch, recursive = TRUE)
dir.create(scratch, recursive = TRUE)

deposited <- read_lines(here::here("original", "ACCG_list_placebo_II_power.R"))
stopifnot(str_trim(deposited[8]) == "setwd()")
deposited[8] <- "# setwd() removed: it is called with no argument and cannot succeed"
write_lines(deposited, file.path(scratch, "ACCG_list_placebo_II_power.R"))

previous_wd <- getwd()
setwd(scratch)
run_env <- new.env(parent = globalenv())
sys.source(file.path(scratch, "ACCG_list_placebo_II_power.R"), envir = run_env)
setwd(previous_wd)
stopifnot(getwd() == previous_wd)

# The deposit accumulates each panel into a data frame of x = treated rate,
# y = control rate, z = power.
deposited_panel <- function(object, total_n) {
  as_tibble(get(object, envir = run_env)) |>
    transmute(treat_pct = round(x * 100), control_pct = round(y * 100),
              power_archive = z, total_n = total_n)
}

archive <- bind_rows(
  deposited_panel("graph.frame.1", 100),
  deposited_panel("graph.frame.2", 200),
  deposited_panel("graph.frame.3", 500),
  deposited_panel("graph.frame.4", 1000)
)

rewrite <- read_csv(
  here::here("maintained", "output", "figure_a2_placebo_ii_power.csv"),
  show_col_types = FALSE
) |>
  mutate(treat_pct = round(pr_treat * 100), control_pct = round(pr_control * 100))

joined <- inner_join(rewrite, archive, by = c("treat_pct", "control_pct", "total_n"))
stopifnot(nrow(joined) == nrow(rewrite))

# What the missing strict argument costs in the N = 100 panel. Both grids here are
# built the same way, so this comparison is of the argument and nothing else.
strict_grid <- function(strict) {
  expand_grid(treat_pct = round(props * 100), control_pct = round(props * 100)) |>
    mutate(power = map2_dbl(treat_pct, control_pct, \(a, b) {
      power.prop.test(n = 50, p1 = a / 100, p2 = b / 100, strict = strict)$power
    }))
}

strict_effect <- strict_grid(strict = TRUE) |>
  rename(power_strict = power) |>
  left_join(strict_grid(strict = FALSE), by = c("treat_pct", "control_pct")) |>
  mutate(gap = power_strict - power)

text_figure_a2_archive_grid <- tibble(
  claim = c(
    "Cells compared with the deposited grid",
    "Cells where both grids are defined",
    "Cells undefined in both grids",
    "Cells defined in one grid and not the other",
    "Maximum absolute difference from the deposited grid",
    "Maximum power the N = 100 panel gains from strict = TRUE",
    "Where that maximum falls: Pr(Y=1|Z=1)",
    "Where that maximum falls: Pr(Y=1|Z=0)"
  ),
  value = c(
    nrow(joined),
    sum(!is.na(joined$power) & !is.na(joined$power_archive)),
    sum(is.na(joined$power) & is.na(joined$power_archive)),
    sum(is.na(joined$power) != is.na(joined$power_archive)),
    max(abs(joined$power - joined$power_archive), na.rm = TRUE),
    max(strict_effect$gap, na.rm = TRUE),
    strict_effect$treat_pct[which.max(strict_effect$gap)] / 100,
    strict_effect$control_pct[which.max(strict_effect$gap)] / 100
  )
)

write_csv(text_figure_a2_archive_grid,
          here::here("maintained", "output", "text_figure_a2_archive_grid.csv"))

print(text_figure_a2_archive_grid, n = Inf, width = 200)
