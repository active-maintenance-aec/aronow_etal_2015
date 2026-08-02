# aronow_etal_2015/maintained/text_placebo_i_sampler.R
# Output: maintained/output/text_placebo_i_sampler.csv
# Depends on: helpers.R
# Description: The computational reproducibility check for Figure A1, which asks a
#   question about the deposit rather than about the rewrite. R 3.6.0 replaced the
#   sampler behind sample(), and the Figure A1 simulation calls sample() four times
#   per simulated experiment, so the analysis of 2015 cannot be re-run byte for byte
#   under the current default. RNGkind(sample.kind = "Rounding") restores the
#   sampler of the day.
#
#   The rewrite itself keeps the modern sampler: it is the code we would write now,
#   and the current sampler is the correct one. This script measures what the choice
#   is worth by running a coarse slice of the first panel's grid under each sampler
#   from identical per-cell seeds, and comparing the gap against the simulation
#   error of a 1,000-run cell. The deposit sets no seed at all, so neither sampler
#   can reproduce the published figure cell for cell in any case.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

sims <- 1000

# Every eleventh column and every third row of the published 19 by 101 grid.
slice_grid <- expand_grid(
  admitter_n = seq(100, 1000, by = 150),
  prop = seq(0, 1, by = 0.1)
)

panel_1_power <- function(seeds) {
  map_dbl(seq_len(nrow(slice_grid)), function(i) {
    set.seed(seeds[i])
    cell <- slice_grid[i, ]
    n_true <- floor(cell$admitter_n * (1 - cell$prop))
    mean(replicate(sims, list_simulator(
      N_trueadmitter = n_true,
      N_falseconfessor = cell$admitter_n - n_true,
      N_withholder = 200,
      N_innocent = 200,
      baseline_binomial_prob = 0.4
    )))
  })
}

set.seed(20150410)
seeds <- sample.int(.Machine$integer.max, nrow(slice_grid))

# Current sampler ----
current <- panel_1_power(seeds)

# The sampler of 2015 ----
# on.exit() does not reliably restore the sampler at the top level of a sourced
# file, and run_all.R sources this in the middle of a sequence, so it is restored
# explicitly below and the restoration is asserted.
old_kind <- RNGkind()
suppressWarnings(RNGkind(sample.kind = "Rounding"))
rounding <- panel_1_power(seeds)
suppressWarnings(RNGkind(sample.kind = old_kind[3]))
stopifnot(RNGkind()[3] == old_kind[3])

comparison <- slice_grid |>
  mutate(
    power_current_sampler = current,
    power_rounding_sampler = rounding,
    difference = power_current_sampler - power_rounding_sampler
  )

write_csv(comparison, here::here("maintained", "output", "text_placebo_i_sampler.csv"))

# The simulation error of a single cell is sqrt(p (1 - p) / sims), largest at
# p = 0.5. Two independent cells differ by sqrt(2) times that on average.
print(comparison |>
  summarize(
    cells = n(),
    mean_abs_difference = mean(abs(difference)),
    max_abs_difference = max(abs(difference)),
    mc_se_at_half = sqrt(0.25 / sims)
  ))
