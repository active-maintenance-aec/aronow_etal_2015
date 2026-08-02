# aronow_etal_2015/run_all.R
# Output: maintained/output/, ground_truth/, report/run_timings.csv
# Depends on: download_original.R, maintained/, ground_truth/
# Description: Runs the whole reproduction in order: fetch and verify the deposited
#   archive, build the two analysis frames, then every published table and figure,
#   then the ground truth. Every script is self-contained and can also be run on its
#   own. Each step is timed and the timings are written out, so that anything the
#   report says about how long the run takes is measured rather than remembered.

library(here)
here::i_am("run_all.R")

timings <- tibble::tibble(step = character(), seconds = numeric())

run_step <- function(path, label = basename(path)) {
  elapsed <- system.time(source(here::here(path), local = FALSE))[["elapsed"]]
  timings <<- tibble::add_row(timings, step = label, seconds = elapsed)
  invisible(elapsed)
}

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums and byte sizes
# either way, and stops if original/ holds anything the manifest does not list.
run_step("download_original.R")

# Cleaning ----
run_step(file.path("maintained", "clean_listdirect.R"))

# Tables ----
table_scripts <- c(
  "table_1_treatment_ns.R",
  "table_2_covariate_balance.R",
  "table_3_study_a_prevalence.R",
  "table_4_study_a_placebo_i.R",
  "table_5_study_a_placebo_ii.R",
  "table_6_study_b_prevalence.R",
  "table_7_study_b_placebo_i.R",
  "table_8_study_b_placebo_ii.R",
  "table_a1_factorial.R",
  "table_a2_rep_study_a_prevalence.R",
  "table_a3_rep_study_a_placebo_i.R",
  "table_a4_rep_study_a_placebo_ii.R",
  "table_a5_rep_study_b_prevalence.R",
  "table_a6_rep_study_b_placebo_i.R",
  "table_a7_rep_study_b_placebo_ii.R",
  "table_a8_rep_factorial.R"
)

for (script in table_scripts) run_step(file.path("maintained", script))

# Figures ----
# Figures 1 and 2 read the Table 3 and Table 6 estimates, so they run after the
# table scripts. figure_a1 is the slow step: 7,676 grid cells at 1,000 simulated
# experiments each.
run_step(file.path("maintained", "figure_1_study_a_prevalence.R"))
run_step(file.path("maintained", "figure_2_study_b_prevalence.R"))
run_step(file.path("maintained", "figure_a1_placebo_i_power.R"))
run_step(file.path("maintained", "figure_a2_placebo_ii_power.R"))

# In-text quantities and the two figure checks ----
# The power figures print no numbers, so each is checked against something else:
# Figure A2 against the deposited grid, Figure A1 against itself under the sampler
# R used when the paper was written.
run_step(file.path("maintained", "text_sample_sizes.R"))
run_step(file.path("maintained", "text_figure_a2_archive_grid.R"))
run_step(file.path("maintained", "text_placebo_i_sampler.R"))

# Ground truth ----
# run_archive.R runs the deposited scripts in a scratch copy stripped to data plus
# code and captures every quantity the article prints; build_ground_truth.R joins
# that to the published values and to maintained/output/.
run_step(file.path("ground_truth", "run_archive.R"))
run_step(file.path("ground_truth", "build_ground_truth.R"))

# Re-verify the deposit ----
# The gate inside download_original.R is a precondition, and it ran before any of
# the above. Running it again afterwards is what catches a script that damaged
# original/ during the run, which would otherwise go unnoticed until the next one.
run_step("download_original.R", label = "download_original.R (re-verification)")

# Timings ----
# Written outside maintained/output/, whose diff is the reproduction check and
# would otherwise never come back clean.
dir.create(here::here("report"), showWarnings = FALSE)

readr::write_csv(timings, here::here("report", "run_timings.csv"))

print(timings, n = Inf)
print(paste("Total elapsed:", round(sum(timings$seconds), 1), "seconds"))
