# aronow_etal_2015/maintained/figure_a1_placebo_i_power.R
# Output: maintained/output/figure_a1_placebo_i_power.pdf
#         maintained/output/figure_a1_placebo_i_power.png
#         maintained/output/figure_a1_placebo_i_power.csv
# Depends on: helpers.R
# Description: Figure A1, the power of Placebo Test I to detect violations of
#   Monotonicity, No Liars and No Design Effects, and its sensitivity to the
#   variability of the non-sensitive items. Four Monte Carlo panels of 1,919
#   cells each, 1,000 simulated experiments per cell.
#
#   The deposited script sets no seed, so the published figure cannot be
#   reproduced cell for cell, only up to Monte Carlo error of sqrt(0.25 / 1000)
#   at power 0.5. This script seeds each cell separately from one seeded stream,
#   which makes the result identical run to run and independent of how many cores
#   the machine has. It is the slow step of the pipeline; run_all.R records how
#   long it took in report/run_timings.csv.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

set.seed(20150410)

sims <- 1000
n_cores <- if (.Platform$OS.type == "windows") 1L else max(1L, detectCores() - 1L)

admitter_ns <- seq(100, 1000, by = 50)
props <- seq(0, 1, by = 0.01)

# Each cell draws its own seed before running its 1,000 simulated experiments,
# so the grid is deterministic whatever order the workers finish in.
panel_power <- function(grid, sim) {
  seeds <- sample.int(.Machine$integer.max, nrow(grid))
  powers <- mclapply(seq_len(nrow(grid)), function(i) {
    set.seed(seeds[i])
    cell <- grid[i, ]
    mean(replicate(sims, sim(cell)))
  }, mc.cores = n_cores)
  # A worker that fails returns a try-error, which unlist would turn into a
  # character column rather than an error, so the type is checked before use.
  stopifnot(all(map_lgl(powers, \(p) is.numeric(p) && length(p) == 1)))
  mutate(grid, power = unlist(powers))
}

# Panel 1: violated assumption, no false confessions ----
grid_1 <- expand_grid(admitter_n = admitter_ns, prop = props) |>
  panel_power(\(cell) list_simulator(
    N_trueadmitter = floor(cell$admitter_n * (1 - cell$prop)),
    N_falseconfessor = cell$admitter_n - floor(cell$admitter_n * (1 - cell$prop)),
    N_withholder = 200,
    N_innocent = 200,
    baseline_binomial_prob = 0.4
  ))

# Panel 2: violated assumption, no liars ----
grid_2 <- expand_grid(admitter_n = admitter_ns, prop = props) |>
  panel_power(\(cell) list_simulator(
    N_trueadmitter = cell$admitter_n,
    N_falseconfessor = 0,
    N_withholder = 200,
    N_innocent = 200,
    pr_listliar = cell$prop,
    baseline_binomial_prob = 0.4
  ))

# Panel 3: violated assumption, no design effects ----
grid_3 <- expand_grid(admitter_n = admitter_ns, prop = props) |>
  panel_power(\(cell) list_simulator(
    N_trueadmitter = cell$admitter_n,
    N_falseconfessor = 0,
    N_withholder = 200,
    N_innocent = 200,
    pr_designaffected = cell$prop,
    baseline_binomial_prob = 0.4
  ))

# Panel 4: variability of responses to the non-sensitive items ----
grid_4 <- expand_grid(admitter_n = admitter_ns, prop = props) |>
  panel_power(\(cell) list_simulator(
    N_trueadmitter = floor(cell$admitter_n * 0.80),
    N_falseconfessor = cell$admitter_n - floor(cell$admitter_n * 0.80),
    N_withholder = 200,
    N_innocent = 200,
    baseline_binomial_prob = cell$prop
  ))

panels <- bind_rows(
  grid_1 |> mutate(panel = "no false confessions"),
  grid_2 |> mutate(panel = "no liars"),
  grid_3 |> mutate(panel = "no design effects"),
  grid_4 |> mutate(panel = "baseline variability")
)

write_csv(panels, here::here("maintained", "output", "figure_a1_placebo_i_power.csv"))

# Figure ----
p1 <- ggplot(grid_1, aes(x = prop, y = admitter_n, fill = power)) +
  geom_tile() +
  scale_power_fill() +
  labs(x = "Proportion of false confessors",
       y = "Total Number of Admitters",
       title = "Violated assumption: no false confessions") +
  power_panel_theme

p2 <- ggplot(grid_2, aes(x = prop, y = admitter_n, fill = power)) +
  geom_tile() +
  scale_power_fill() +
  labs(x = "Proportion of liars on the treatment list",
       y = "Total Number of Admitters",
       title = "Violated assumption: no liars") +
  power_panel_theme

p3 <- ggplot(grid_3, aes(x = prop, y = admitter_n, fill = power)) +
  geom_tile() +
  scale_power_fill() +
  labs(x = 'Proportion of "Design Affected"',
       y = "Total Number of Admitters",
       title = "Violated assumption: no design effects") +
  power_panel_theme

p4 <- ggplot(grid_4, aes(x = prop, y = admitter_n, fill = power)) +
  geom_tile() +
  scale_power_fill() +
  labs(x = "Probability p of binomial distribution with 4 trials",
       y = "Total Number of Admitters (20% False Confessors)",
       title = "Variability of responses to non-sensitive items") +
  power_panel_theme

g <- (p1 | p2) / (p3 | p4) + plot_layout(guides = "collect")

ggsave(
  here::here("maintained", "output", "figure_a1_placebo_i_power.pdf"),
  plot = g, width = 12, height = 12
)
ggsave(
  here::here("maintained", "output", "figure_a1_placebo_i_power.png"),
  plot = g, width = 12, height = 12, dpi = 300
)

print(panels |> summarize(cells = n(), min_power = min(power),
                          mean_power = mean(power), max_power = max(power),
                          .by = panel))
