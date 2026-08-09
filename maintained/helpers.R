# aronow_etal_2015/maintained/helpers.R
# Output: none
# Depends on: nothing
# Description: Packages, the paper's estimators and placebo tests, the list
#   experiment simulator used by the Figure A1 power analysis, and the shared
#   power colour scale. Every other script sources this file first.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

library(here)
library(tidyverse)
library(patchwork)
library(parallel)

# Anchors a script run on its own rather than through run_all.R.
here::i_am("maintained/helpers.R")

# V = list response, Z = treatment assignment, Y = direct question response.
# The estimators below are the ones defined in the deposited ACCG_list_source.R
# and derived in sections 3 and 4 of the article. They are closed form rather
# than regression based, so they are carried over verbatim rather than replaced
# by a modelling call.

items <- c("Nuclear Power", "Public Transportation", "Spanish-speaking",
           "Muslim Teachers", "CNN")

# Estimators ----

direct_est <- function(Y) mean(Y)

direct_se <- function(Y) sqrt(var(Y) / length(Y))

conv_est <- function(V, Z) mean(V[Z == 1]) - mean(V[Z == 0])

conv_se <- function(V, Z) {
  sqrt(var(V[Z == 1]) / sum(Z) + var(V[Z == 0]) / sum(1 - Z))
}

combined_est <- function(V, Z, Y) {
  mean(Y) + mean(1 - Y) * (mean(V[Z == 1 & Y == 0]) - mean(V[Z == 0 & Y == 0]))
}

combined_se <- function(V, Z, Y) {
  mu_hat <- combined_est(V, Z, Y)
  y_bar <- direct_est(Y)
  var_z1 <- var(V[Z == 1 & Y == 0])
  var_z0 <- var(V[Z == 0 & Y == 0])
  gamma_hat <- mean(Z)
  var_est <- (((1 - mu_hat)^2 / (1 - y_bar)) * y_bar +
                (1 - y_bar) * (var_z1 / gamma_hat + var_z0 / (1 - gamma_hat))) /
    length(V)
  sqrt(var_est)
}

var_reduction <- function(V, Z, Y) {
  (1 - combined_se(V, Z, Y)^2 / conv_se(V, Z)^2) * 100
}

whole_shebang <- function(V, Z, Y) {
  tibble(
    direct = direct_est(Y),
    direct_se = direct_se(Y),
    conv = conv_est(V, Z),
    conv_se = conv_se(V, Z),
    combined = combined_est(V, Z, Y),
    combined_se = combined_se(V, Z, Y),
    var_reduc = var_reduction(V, Z, Y)
  )
}

# Placebo tests ----
# Placebo Test I tests beta = 1 among subjects who answer "Yes" to the direct
# question, so the test statistic is centred on 1 rather than on 0. The deposited
# script labels the column Pr(beta = 0); the published tables call it "p-value".

placebo_i_test <- function(V, Z, Y) {
  treat_admit <- V[Y == 1 & Z == 1]
  control_admit <- V[Y == 1 & Z == 0]
  est <- mean(treat_admit) - mean(control_admit)
  se <- sqrt(var(treat_admit) / length(treat_admit) +
               var(control_admit) / length(control_admit))
  tibble(
    beta = est,
    se = se,
    p_value = 2 * pnorm(-abs(est - 1) / se),
    n = length(treat_admit) + length(control_admit)
  )
}

placebo_ii_test <- function(Z, Y) {
  delta_hat <- sum(Y * Z) / sum(Z) - sum(Y * (1 - Z)) / sum(1 - Z)
  se <- sqrt(var(Y[Z == 1]) / sum(Z) + var(Y[Z == 0]) / sum(1 - Z))
  tibble(
    beta = delta_hat,
    se = se,
    p_value = 2 * pnorm(-abs(delta_hat) / se),
    n = length(Y)
  )
}

# Table assembly ----
# The five list experiments are stored one per column group: list<k>N is the list
# response, list<k>treat the assignment, direct<k> the direct question.

prevalence_table <- function(df) {
  map(1:5, \(k) whole_shebang(
    V = df[[str_glue("list{k}N")]],
    Z = df[[str_glue("list{k}treat")]],
    Y = df[[str_glue("direct{k}")]]
  )) |>
    list_rbind() |>
    mutate(item = items, .before = everything())
}

placebo_i_table <- function(df) {
  map(1:5, \(k) placebo_i_test(
    V = df[[str_glue("list{k}N")]],
    Z = df[[str_glue("list{k}treat")]],
    Y = df[[str_glue("direct{k}")]]
  )) |>
    list_rbind() |>
    mutate(item = items, .before = everything())
}

placebo_ii_table <- function(df) {
  map(1:5, \(k) placebo_ii_test(
    Z = df[[str_glue("list{k}treat")]],
    Y = df[[str_glue("direct{k}")]]
  )) |>
    list_rbind() |>
    mutate(item = items, .before = everything())
}

# The factorial comparison differences the two studies item by item. The two
# studies are separate subjects, so the standard error of a difference is the
# root of the sum of squared standard errors.
factorial_table <- function(df) {
  study_a <- prevalence_table(filter(df, listsfirst == 0))
  study_b <- prevalence_table(filter(df, listsfirst == 1))
  tibble(
    item = items,
    direct_diff = study_a$direct - study_b$direct,
    direct_se = sqrt(study_a$direct_se^2 + study_b$direct_se^2),
    conv_diff = study_a$conv - study_b$conv,
    conv_se = sqrt(study_a$conv_se^2 + study_b$conv_se^2),
    combined_diff = study_a$combined - study_b$combined,
    combined_se = sqrt(study_a$combined_se^2 + study_b$combined_se^2)
  )
}

# Simulator for the Figure A1 power analysis ----
# design_affector shifts a subject's control list count up by one unless it is
# already at the ceiling of four, which is the design effect the simulation
# introduces.

design_affector <- function(x) {
  x_star <- x
  x_star[x != 4] <- x[x != 4] + 1
  x_star
}

list_simulator <- function(N_trueadmitter, N_falseconfessor, N_withholder,
                           N_innocent, pr_listliar = 0, pr_designaffected = 0,
                           baseline_binomial_prob = 0.5) {
  N <- N_trueadmitter + N_withholder + N_falseconfessor + N_innocent
  N_engager <- N_trueadmitter + N_withholder
  N_listliar <- floor(N_engager * pr_listliar)
  N_designaffected <- floor(N * pr_designaffected)

  Ystar <- c(rep(1L, N_engager), rep(0L, N - N_engager))
  withholder <- c(
    if_else(seq_len(N_engager) %in% sample(N_engager, N_withholder), 1L, 0L),
    rep(0L, N - N_engager)
  )
  falseconfessor <- c(
    rep(0L, N_engager),
    if_else(seq_len(N - N_engager) %in% sample(N - N_engager, N_falseconfessor), 1L, 0L)
  )
  listliar <- c(
    if_else(seq_len(N_engager) %in% sample(N_engager, N_listliar), 1L, 0L),
    rep(0L, N - N_engager)
  )
  designaffected <- if_else(seq_len(N) %in% sample(N, N_designaffected), 1L, 0L)

  Y <- Ystar * (1 - withholder) + (1 - Ystar) * falseconfessor
  V0 <- rbinom(N, size = 4, prob = baseline_binomial_prob)
  V1 <- V0 + Ystar * (1 - listliar)
  V1[designaffected == 1] <- design_affector(V0[designaffected == 1]) +
    Ystar[designaffected == 1] * (1 - listliar[designaffected == 1])

  Z <- if_else(seq_len(N) %in% sample(N, N / 2), 1L, 0L)
  V <- V1 * Z + (1 - Z) * V0

  as.integer(placebo_i_test(V, Z, Y)[["p_value"]] < 0.05)
}

# Power figures ----
# The published levelplots use a white-to-black ramp with a red band marking the
# 0.75 to 0.85 power region. The same colours are carried into the ggplot2 fill.

power_colors <- colorRampPalette(c("white", "black"))(100)
power_colors[75:85] <- c("red4", "red3", "red3", "red2", "red2", "red",
                         "red2", "red2", "red3", "red3", "red4")

scale_power_fill <- function() {
  scale_fill_gradientn(
    colors = power_colors,
    limits = c(0, 1),
    breaks = c(0, 0.25, 0.5, 0.75, 1),
    name = "Power"
  )
}

power_panel_theme <- theme_bw() +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 10),
    axis.title = element_text(size = 9)
  )

# Blank a figure PDF's embedded timestamps ----
# R's pdf() device stamps /CreationDate and /ModDate with the wall clock, so an
# otherwise deterministic pipeline writes a different file on every run. The epoch
# string is the same width as what it replaces, which keeps the cross-reference byte
# offsets valid, and a file with no timestamp is left alone.
blank_pdf_timestamps <- function(path) {
  epoch <- charToRaw("D:19700101000000")
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  if (length(hits) == 0) return(invisible(path))
  for (h in hits) raw_pdf[h:(h + length(epoch) - 1L)] <- epoch
  writeBin(raw_pdf, path)
  invisible(path)
}
