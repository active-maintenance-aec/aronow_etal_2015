# aronow_etal_2015/maintained/figure_2_study_b_prevalence.R
# Output: maintained/output/figure_2_study_b_prevalence.pdf
#         maintained/output/figure_2_study_b_prevalence.png
#         maintained/output/figure_2_study_b_prevalence.csv
# Depends on: maintained/output/table_6_study_b_prevalence.csv, helpers.R
# Description: Figure 2, the three estimates of prevalence for Study B with 95
#   percent confidence intervals. It reads the Table 6 estimates rather than
#   recomputing them, so the figure and the table cannot disagree.
#
# Aronow, Peter M., Alexander Coppock, Forrest W. Crawford, and Donald P. Green.
# 2015. "Combining List Experiment and Direct Question Estimates of Sensitive
# Behavior Prevalence." Journal of Survey Statistics and Methodology 3(1): 43-66.

source(here::here("maintained", "helpers.R"))

estimators <- c("Direct Estimate", "Standard List Estimate", "Combined Estimate")

gg_df <- read_csv(
  here::here("maintained", "output", "table_6_study_b_prevalence.csv"),
  show_col_types = FALSE
) |>
  pivot_longer(
    cols = c(direct, conv, combined),
    names_to = "estimator",
    values_to = "est"
  ) |>
  mutate(
    se = case_when(
      estimator == "direct" ~ direct_se,
      estimator == "conv" ~ conv_se,
      estimator == "combined" ~ combined_se
    ),
    estimator = factor(
      recode_values(estimator,
                    "direct" ~ "Direct Estimate",
                    "conv" ~ "Standard List Estimate",
                    "combined" ~ "Combined Estimate"),
      levels = estimators
    ),
    item = factor(item, levels = items),
    li = est - 1.96 * se,
    ui = est + 1.96 * se
  )

# The plotted values are written out as well as drawn, so that a fresh run can be
# diffed against the committed figure by its numbers rather than by its bytes.
write_csv(
  gg_df |> select(item, estimator, est, se, li, ui),
  here::here("maintained", "output", "figure_2_study_b_prevalence.csv")
)

g <- ggplot(gg_df, aes(x = item, y = est, fill = estimator)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_errorbar(
    aes(ymin = li, ymax = ui),
    position = position_dodge(width = 0.8),
    width = 0.2
  ) +
  scale_fill_grey(start = 0.35, end = 0.85) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  coord_cartesian(ylim = c(0, 1.05)) +
  labs(y = "Prevalence", x = NULL, fill = NULL) +
  theme_bw() +
  theme(
    legend.position = "top",
    legend.key.width = unit(1, "lines"),
    axis.text.x = element_text(angle = 15, hjust = 1),
    panel.grid.major.x = element_blank()
  )

ggsave(
  here::here("maintained", "output", "figure_2_study_b_prevalence.pdf"),
  plot = g, width = 10, height = 7
)
ggsave(
  here::here("maintained", "output", "figure_2_study_b_prevalence.png"),
  plot = g, width = 10, height = 7, dpi = 300
)

print(gg_df |> select(item, estimator, est, se, li, ui), n = Inf)
