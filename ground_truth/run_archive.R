# aronow_etal_2015/ground_truth/run_archive.R
# Output: ground_truth/archive_values.csv
# Depends on: original/ (run download_original.R first)
# Description: Run the deposited analysis scripts and capture every quantity the
#   article prints, so that the archive column of the ground truth is read out of
#   a run rather than transcribed. The deposit is copied to a scratch directory
#   first and is never written to, and the copy is patched only in the ways listed
#   in the edits table below: the working directory calls are neutralised, the
#   missing library call is added, and one line is appended after each published
#   table is assembled to record the object before the next table overwrites it.
#   Every edit asserts the text of the line it targets, so a change to the deposit
#   stops the script instead of silently patching the wrong line.
#
#   The two power scripts are not run here, and neither prints a number: each
#   builds a grid, draws it with lattice and writes PDFs. The deposited Figure A2
#   script is run in full by maintained/text_figure_a2_archive_grid.R, which
#   compares its grid with the rewrite's cell by cell. The deposited Figure A1
#   script sets no seed, so its grid is one unlabelled draw and differs from itself
#   run to run; comparing the rewrite against a single draw of it would measure
#   nothing, so maintained/text_placebo_i_sampler.R measures the dispersion instead.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

items <- c("Nuclear Power", "Public Transportation", "Spanish-speaking",
           "Muslim Teachers", "CNN")

# The scratch copy ----
# The deposit is flat, but its own readme.txt describes a /programs and /data
# layout and the scripts read from those paths, so the copy restores them.
scratch <- file.path(tempdir(), "aronow_etal_2015_archive")
unlink(scratch, recursive = TRUE)
dir.create(file.path(scratch, "programs"), recursive = TRUE)
dir.create(file.path(scratch, "data"), recursive = TRUE)

deposit <- function(f) here::here("original", f)
copied <- c(
  file.copy(deposit("ACCG_list_source.R"), file.path(scratch, "programs")),
  file.copy(deposit("ACCG_main_experiment.csv"), file.path(scratch, "data")),
  file.copy(deposit("ACCG_replication_experiment.csv"), file.path(scratch, "data"))
)
stopifnot(all(copied))

# Edits ----
# Each row names a line of a deposited script, the text that line must have, and
# what to do with it. "replace" swaps the line; "after" appends a line below it.
edits <- tribble(
  ~script, ~line, ~action, ~expect, ~code,

  "ACCG_list_main_experiment.R", 9, "replace",
  'setwd("/Users/Alex/Documents/Dropbox/Columbia/Collaboration/Work for Don/list experiments/ACCG_list_replication_archive/")',
  "# setwd() removed: the path is the first author's 2015 home directory",

  "ACCG_list_main_experiment.R", 32, "after",
  "treatment_ns_ordered <-  treatment_ns_ordered[c(2,1,4,3,6,5,8,7,10,9,12,11),]",
  '.capture("table_1", treatment_ns_ordered)',

  "ACCG_list_main_experiment.R", 42, "after",
  "age_table <- round(prop.table(table(main_exp$age, main_exp$firstbyone), margin =2)*100 ,digits=2)",
  '.capture("balance_age", age_table)',

  "ACCG_list_main_experiment.R", 45, "after",
  "gender_table <- round(prop.table(table(main_exp$gender, main_exp$firstbyone), margin =2)*100 ,digits=2)",
  '.capture("balance_gender", gender_table)',

  "ACCG_list_main_experiment.R", 49, "after",
  "ideology_table <- ideology_table[c(3,4,1,2),]",
  '.capture("balance_ideology", ideology_table)',

  "ACCG_list_main_experiment.R", 53, "after",
  "education_table <- education_table[c(4,3,5,1,2),]",
  '.capture("balance_education", education_table)',

  "ACCG_list_main_experiment.R", 57, "after",
  "race_table <- race_table[c(7,1,2,3,4,5,6),]",
  '.capture("balance_race", race_table)',

  "ACCG_list_main_experiment.R", 60, "after",
  "treatment_group_ns <- round(table(main_exp$firstbyone), digits=0)",
  '.capture("balance_n", treatment_group_ns)',

  "ACCG_list_main_experiment.R", 92, "after",
  'colnames(studyA_results) <- c("Direct Question", "Direct SE", "Conventional Estimate", "Conventional SE", "New Estimate", "New SE", "Variance Improvement")',
  '.capture("table_3", studyA_results)',

  "ACCG_list_main_experiment.R", 105, "after",
  'rownames(placebo_I_table) <- c("Nuclear Power","Public Transportation", "Spanish-speaking", "Muslim Teachers", "CNN")',
  '.capture("table_4", placebo_I_table)',

  "ACCG_list_main_experiment.R", 118, "after",
  'colnames(placebo_II_table) <- c("Estimate", "SE", "p-value", "n")',
  '.capture("table_5", placebo_II_table)',

  "ACCG_list_main_experiment.R", 134, "after",
  'colnames(studyB_results) <- c("Direct Question", "Direct SE", "Conventional Estimate", "Conventional SE", "New Estimate", "New SE", "Variance Improvement")',
  '.capture("table_6", studyB_results)',

  "ACCG_list_main_experiment.R", 146, "after",
  'rownames(placebo_I_table) <- c("Nuclear Power","Public Transportation", "Spanish-speaking", "Muslim Teachers", "CNN")',
  '.capture("table_7", placebo_I_table)',

  "ACCG_list_main_experiment.R", 159, "after",
  'colnames(placebo_II_table) <- c("Estimate", "SE", "p-value", "n")',
  '.capture("table_8", placebo_II_table)',

  "ACCG_list_main_experiment.R", 188, "after",
  'colnames(factorial_design_table) <- rep(c("Difference", "SE"), 3)',
  '.capture("table_a1", factorial_design_table)',

  "ACCG_list_replication_experiment.R", 6, "replace",
  "library(lmtest)",
  "library(lmtest); library(xtable)",

  "ACCG_list_replication_experiment.R", 9, "replace",
  'setwd("/Users/Alex/Documents/Dropbox/Columbia/Collaboration/Work for Don/list experiments/ACCG_list_replication_archive/")',
  "# setwd() removed: the path is the first author's 2015 home directory",

  "ACCG_list_replication_experiment.R", 44, "after",
  'colnames(studyA_results) <- c("Direct Question", "Direct SE", "Conventional Estimate", "Conventional SE", "New Estimate", "New SE", "Variance Improvement")',
  '.capture("table_a2", studyA_results)',

  "ACCG_list_replication_experiment.R", 57, "after",
  'rownames(placebo_I_table) <- c("Nuclear Power","Public Transportation", "Spanish-speaking", "Muslim Teachers", "CNN")',
  '.capture("table_a3", placebo_I_table)',

  "ACCG_list_replication_experiment.R", 71, "after",
  'colnames(placebo_II_table) <- c("Estimate", "SE", "p-value", "n")',
  '.capture("table_a4", placebo_II_table)',

  "ACCG_list_replication_experiment.R", 87, "after",
  'colnames(studyB_results) <- c("Direct Question", "Direct SE", "Conventional Estimate", "Conventional SE", "New Estimate", "New SE", "Variance Improvement")',
  '.capture("table_a5", studyB_results)',

  "ACCG_list_replication_experiment.R", 99, "after",
  'rownames(placebo_I_table) <- c("Nuclear Power","Public Transportation", "Spanish-speaking", "Muslim Teachers", "CNN")',
  '.capture("table_a6", placebo_I_table)',

  "ACCG_list_replication_experiment.R", 111, "after",
  'colnames(placebo_II_table) <- c("Estimate", "SE", "p-value", "n")',
  '.capture("table_a7", placebo_II_table)',

  "ACCG_list_replication_experiment.R", 140, "after",
  'colnames(factorial_design_table) <- rep(c("Difference", "SE"), 3)',
  '.capture("table_a8", factorial_design_table)'
)

# Insertions shift every line below them, so the edits are applied from the
# bottom of each file upwards.
patch_script <- function(script) {
  lines <- read_lines(deposit(script))
  script_edits <- edits |> filter(script == !!script) |> arrange(desc(line))
  for (i in seq_len(nrow(script_edits))) {
    e <- script_edits[i, ]
    stopifnot(str_trim(lines[e$line]) == e$expect)
    lines <- if (e$action == "replace") {
      replace(lines, e$line, e$code)
    } else {
      append(lines, e$code, after = e$line)
    }
  }
  write_lines(lines, file.path(scratch, "programs", script))
}

walk(unique(edits$script), patch_script)

# The stripped-copy check ----
# The copy holds the deposited data and the deposited code and nothing else. That
# matters because an archive that ships its own intermediates lets a script pass
# while the script that was supposed to build its inputs has failed, and the pass
# is silent. Here it is asserted rather than assumed, and the contents are recorded.
stripped_contents <- sort(list.files(scratch, recursive = TRUE))
stopifnot(setequal(stripped_contents, c(
  "data/ACCG_main_experiment.csv",
  "data/ACCG_replication_experiment.csv",
  "programs/ACCG_list_main_experiment.R",
  "programs/ACCG_list_replication_experiment.R",
  "programs/ACCG_list_source.R"
)))

# Run ----
# The capture collector sits in the parent of the evaluation environment, so the
# scripts' own rm(list = ls()) cannot reach it.
store <- new.env()
collector <- new.env()
collector$.capture <- function(name, value) assign(name, value, envir = store)

run_deposited <- function(script) {
  run_env <- new.env(parent = collector)
  outcome <- tryCatch({
    sys.source(file.path(scratch, "programs", script), envir = run_env)
    "runs to completion"
  }, error = \(e) paste("error:", conditionMessage(e)))
  tibble(script = script, stripped_copy = TRUE, outcome = outcome)
}

previous_wd <- getwd()
setwd(scratch)
script_status <- map(
  c("ACCG_list_main_experiment.R", "ACCG_list_replication_experiment.R"),
  run_deposited
) |>
  list_rbind()
setwd(previous_wd)
stopifnot(getwd() == previous_wd)

write_csv(script_status, here::here("ground_truth", "archive_script_status.csv"))
print(script_status, width = Inf)

stopifnot(all(script_status$outcome == "runs to completion"))

# Reshape the captured objects into one long table ----
long_matrix <- function(m, rows, cols) {
  as_tibble(matrix(as.numeric(m), nrow = nrow(m)), .name_repair = ~ cols) |>
    mutate(row = rows, .before = everything()) |>
    pivot_longer(-row, names_to = "col", values_to = "value_script")
}

# Table 1 is the only table whose blank cells are structural: the deposit fills
# the lower block triangle with NA and the article prints it empty.
conditions <- c("Study A", "Study B", "List 1 T", "List 1 C", "List 2 T", "List 2 C",
                "List 3 T", "List 3 C", "List 4 T", "List 4 C", "List 5 T", "List 5 C")

table_1 <- long_matrix(store$table_1, conditions, conditions) |>
  transmute(table_figure = "table_1", claim = str_glue("{row} x {col}"), value_script) |>
  drop_na(value_script)

# The balance columns come out of table() in the order of firstbyone, which codes
# 0 = Study B control, 1 = Study A control, 2 = Study B treat, 3 = Study A treat.
# The deposit reorders them c(4, 2, 3, 1) to print; the same reordering is applied
# here so the captured columns carry the published labels.
balance_groups <- c("Study A Treat", "Study A Control", "Study B Treat", "Study B Control")
firstbyone_order <- c(4, 2, 3, 1)

balance_block <- function(obj) {
  long_matrix(obj[, firstbyone_order], rownames(obj), balance_groups)
}

table_2 <- bind_rows(
  balance_block(store$balance_age),
  balance_block(store$balance_gender),
  balance_block(store$balance_ideology),
  balance_block(store$balance_education),
  balance_block(store$balance_race),
  long_matrix(matrix(store$balance_n[firstbyone_order], nrow = 1), "n", balance_groups)
) |>
  transmute(table_figure = "table_2", claim = str_glue("{row}: {col}"), value_script)

prevalence_cols <- c("Direct", "Direct SE", "Standard list", "Standard list SE",
                     "Combined", "Combined SE", "% reduction in sampling variance")
placebo_cols <- c("beta", "SE", "p-value", "n")
factorial_cols <- c("Direct difference", "Direct SE",
                    "Conventional list difference", "Conventional list SE",
                    "Combined list difference", "Combined list SE")

analysis_table <- function(name, cols) {
  long_matrix(store[[name]], items, cols) |>
    transmute(table_figure = name, claim = str_glue("{row}: {col}"), value_script)
}

archive_values <- bind_rows(
  table_1,
  table_2,
  analysis_table("table_3", prevalence_cols),
  analysis_table("table_4", placebo_cols),
  analysis_table("table_5", placebo_cols),
  analysis_table("table_6", prevalence_cols),
  analysis_table("table_7", placebo_cols),
  analysis_table("table_8", placebo_cols),
  analysis_table("table_a1", factorial_cols),
  analysis_table("table_a2", prevalence_cols),
  analysis_table("table_a3", placebo_cols),
  analysis_table("table_a4", placebo_cols),
  analysis_table("table_a5", prevalence_cols),
  analysis_table("table_a6", placebo_cols),
  analysis_table("table_a7", placebo_cols),
  analysis_table("table_a8", factorial_cols)
)

write_csv(archive_values, here::here("ground_truth", "archive_values.csv"))

print(count(archive_values, table_figure), n = Inf)
print(str_glue("Captured {nrow(archive_values)} values from the deposited scripts ",
               "under {nrow(edits)} recorded edits."))
