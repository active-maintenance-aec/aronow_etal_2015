# aronow_etal_2015/maintained/figure_a2_placebo_ii_power.R
# Output: maintained/output/figure_a2_placebo_ii_power.pdf
#         maintained/output/figure_a2_placebo_ii_power.png
#         maintained/output/figure_a2_placebo_ii_power.csv
# Depends on: helpers.R
# Description: Figure A2, the power of Placebo Test II to detect violations of
#   Treatment Independence, over the grid of treated and control "Yes" rates, at
#   total sample sizes of 100, 200, 500 and 1,000. Power is analytical, from
#   power.prop.test, so nothing here is simulated.
#
#   The deposited script passes strict = TRUE in three of its four panels and
#   omits it in the N = 100 panel. That inconsistency is carried forward rather
#   than tidied away, because the published figure was drawn with it: strict
#   counts rejections in the wrong direction and so raises power along the
#   diagonal where the two rates are close.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

props <- seq(0, 1, by = 0.01)

# n is per arm, so a total sample of N gives n = N / 2 in each arm.
power_grid <- function(n_per_arm, strict) {
  expand_grid(pr_treat = props, pr_control = props) |>
    mutate(power = map2_dbl(pr_treat, pr_control, \(p1, p2) {
      tryCatch(
        power.prop.test(n = n_per_arm, p1 = p1, p2 = p2, strict = strict)$power,
        error = \(e) NA_real_
      )
    }))
}

grid_100 <- power_grid(50, strict = FALSE)
grid_200 <- power_grid(100, strict = TRUE)
grid_500 <- power_grid(250, strict = TRUE)
grid_1000 <- power_grid(500, strict = TRUE)

panels <- bind_rows(
  grid_100 |> mutate(total_n = 100),
  grid_200 |> mutate(total_n = 200),
  grid_500 |> mutate(total_n = 500),
  grid_1000 |> mutate(total_n = 1000)
)

write_csv(panels, here::here("maintained", "output", "figure_a2_placebo_ii_power.csv"))

# Figure ----
make_panel <- function(grid, title) {
  ggplot(grid, aes(x = pr_treat, y = pr_control, fill = power)) +
    geom_tile() +
    scale_power_fill() +
    labs(x = "Pr(Y=1|Z=1)", y = "Pr(Y=1|Z=0)", title = title) +
    power_panel_theme
}

g <- (make_panel(grid_100, "Power of Placebo Test II\nN = 100") |
        make_panel(grid_200, "Power of Placebo Test II\nN = 200")) /
  (make_panel(grid_500, "Power of Placebo Test II\nN = 500") |
     make_panel(grid_1000, "Power of Placebo Test II\nN = 1000")) +
  plot_layout(guides = "collect")

ggsave(
  here::here("maintained", "output", "figure_a2_placebo_ii_power.pdf"),
  plot = g, width = 12, height = 12
)
ggsave(
  here::here("maintained", "output", "figure_a2_placebo_ii_power.png"),
  plot = g, width = 12, height = 12, dpi = 300
)

print(panels |> summarize(cells = n(), min_power = min(power, na.rm = TRUE),
                          max_power = max(power, na.rm = TRUE), .by = total_n))
