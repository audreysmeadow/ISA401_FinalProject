# 10_exploratory_summaries.R
# Create descriptive summary tables and exploratory charts from the final dataset.

source("R/00_setup.R")

# -----------------------------
# Input and output paths
# -----------------------------

final_input_path <- file.path(final_dir, "us_ev_state_final.csv")

summary_dir <- file.path(exploratory_dir, "summary_tables")
chart_dir <- file.path(exploratory_dir, "charts")
report_output_path <- file.path(exploratory_dir, "exploratory_summary.md")

dir.create(exploratory_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(chart_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(final_input_path) || file.info(final_input_path)$size == 0) {
  stop("Missing final scored dataset. Run R/06_calculate_scores.R first.")
}

state_data <- read_csv(final_input_path, show_col_types = FALSE)

# -----------------------------
# Chart theme and helpers
# -----------------------------

project_theme <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 15, color = "#1F2937"),
    plot.subtitle = element_text(size = 10.5, color = "#4B5563"),
    axis.title = element_text(face = "bold", color = "#374151"),
    axis.text = element_text(color = "#4B5563"),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.title = element_text(face = "bold"),
    legend.text = element_text(size = 9.5),
    legend.key.height = unit(0.35, "cm"),
    legend.key.width = unit(0.45, "cm"),
    plot.caption = element_text(color = "#6B7280", hjust = 0),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(12, 18, 12, 12)
  )

category_palette <- c(
  High = "#0072B2",
  Medium = "#E69F00",
  Low = "#7A7A7A"
)

save_chart <- function(plot, filename, width = 10, height = 6) {
  ggsave(
    filename = file.path(chart_dir, filename),
    plot = plot,
    width = width,
    height = height,
    dpi = 300,
    bg = "white"
  )
}

format_table <- function(data) {
  knitr::kable(data, format = "pipe", align = "l")
}

# -----------------------------
# Summary tables
# -----------------------------

score_summary <- state_data |>
  summarise(
    State_Count = n(),
    Average_Opportunity_Score = round(mean(EV_Opportunity_Score, na.rm = TRUE), 2),
    Median_Opportunity_Score = round(median(EV_Opportunity_Score, na.rm = TRUE), 2),
    Minimum_Opportunity_Score = round(min(EV_Opportunity_Score, na.rm = TRUE), 2),
    Maximum_Opportunity_Score = round(max(EV_Opportunity_Score, na.rm = TRUE), 2),
    Average_EVs_Per_10000_Residents = round(mean(EVs_Per_10000_Residents, na.rm = TRUE), 2),
    Average_Chargers_Per_1000_EVs = round(mean(Chargers_Per_1000_EVs, na.rm = TRUE), 2),
    Average_PlugShare_Per_10000_Residents = round(mean(PlugShare_Per_10000_Residents, na.rm = TRUE), 2)
  )

category_summary <- state_data |>
  count(Opportunity_Category, name = "State_Count") |>
  mutate(
    Percent_of_States = percent(State_Count / sum(State_Count), accuracy = 0.1)
  ) |>
  arrange(match(Opportunity_Category, c("High", "Medium", "Low")))

top_10_states <- state_data |>
  arrange(Opportunity_Rank) |>
  slice_head(n = 10) |>
  transmute(
    Rank = Opportunity_Rank,
    State,
    Category = Opportunity_Category,
    Score = EV_Opportunity_Score,
    `EVs per 10,000 Residents` = EVs_Per_10000_Residents,
    `Chargers per 1,000 EVs` = Chargers_Per_1000_EVs,
    `Economic Readiness` = Economic_Readiness_Score
  )

bottom_10_states <- state_data |>
  arrange(desc(Opportunity_Rank)) |>
  slice_head(n = 10) |>
  arrange(Opportunity_Rank) |>
  transmute(
    Rank = Opportunity_Rank,
    State,
    Category = Opportunity_Category,
    Score = EV_Opportunity_Score,
    `EVs per 10,000 Residents` = EVs_Per_10000_Residents,
    `Chargers per 1,000 EVs` = Chargers_Per_1000_EVs,
    `Economic Readiness` = Economic_Readiness_Score
  )

metric_summary <- state_data |>
  summarise(
    across(
      c(
        EV_Count,
        Population,
        Median_Household_Income,
        Poverty_Rate,
        AFDC_Charging_Station_Count,
        PlugShare_Station_Count,
        EVs_Per_10000_Residents,
        Chargers_Per_1000_EVs,
        EV_Opportunity_Score
      ),
      list(
        Min = ~ min(.x, na.rm = TRUE),
        Median = ~ median(.x, na.rm = TRUE),
        Mean = ~ mean(.x, na.rm = TRUE),
        Max = ~ max(.x, na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    )
  ) |>
  pivot_longer(
    everything(),
    names_to = c("Metric", "Statistic"),
    names_pattern = "(.+)_(Min|Median|Mean|Max)",
    values_to = "Value"
  ) |>
  pivot_wider(names_from = Statistic, values_from = Value) |>
  mutate(across(c(Min, Median, Mean, Max), ~ round(.x, 2))) |>
  arrange(Metric)

write_csv(score_summary, file.path(summary_dir, "score_summary.csv"))
write_csv(category_summary, file.path(summary_dir, "category_summary.csv"))
write_csv(top_10_states, file.path(summary_dir, "top_10_states.csv"))
write_csv(bottom_10_states, file.path(summary_dir, "bottom_10_states.csv"))
write_csv(metric_summary, file.path(summary_dir, "metric_summary.csv"))

# -----------------------------
# Exploratory charts
# -----------------------------

top_15_plot <- state_data |>
  arrange(desc(EV_Opportunity_Score)) |>
  slice_head(n = 15) |>
  mutate(State = fct_reorder(State, EV_Opportunity_Score)) |>
  ggplot(aes(x = EV_Opportunity_Score, y = State, fill = Opportunity_Category)) +
  geom_col(width = 0.72) +
  geom_text(
    aes(label = number(EV_Opportunity_Score, accuracy = 0.1)),
    hjust = -0.15,
    size = 3.5,
    color = "#374151"
  ) +
  scale_fill_manual(values = category_palette) +
  scale_x_continuous(limits = c(0, max(state_data$EV_Opportunity_Score, na.rm = TRUE) * 1.12)) +
  labs(
    title = "Top EV Expansion Opportunity States",
    subtitle = "Final opportunity score combines adoption, infrastructure, visibility, and economic readiness.",
    x = "EV opportunity score",
    y = NULL,
    fill = "Category",
    caption = "Source: Final merged R dataset"
  ) +
  project_theme

adoption_infrastructure_plot <- ggplot(
  state_data,
  aes(
    x = EVs_Per_10000_Residents,
    y = Chargers_Per_1000_EVs,
    color = Opportunity_Category,
    size = Population
  )
) +
  geom_point(alpha = 0.78) +
  geom_text(
    data = state_data |> filter(Opportunity_Rank <= 8),
    aes(label = State_Abbr),
    size = 3.2,
    vjust = -0.85,
    show.legend = FALSE
  ) +
  scale_color_manual(values = category_palette) +
  scale_size_continuous(labels = label_number(scale_cut = cut_short_scale()), range = c(2.5, 8.5)) +
  scale_x_continuous(limits = c(0, max(state_data$EVs_Per_10000_Residents, na.rm = TRUE) * 1.15)) +
  scale_y_continuous(limits = c(0, max(state_data$Chargers_Per_1000_EVs, na.rm = TRUE) * 1.08)) +
  guides(
    color = guide_legend(override.aes = list(size = 4), order = 1),
    size = guide_legend(order = 2)
  ) +
  labs(
    title = "EV Adoption Compared With Charger Availability",
    subtitle = "States in the upper-right have stronger adoption and more chargers relative to registered EVs.",
    x = "EVs per 10,000 residents",
    y = "Chargers per 1,000 EVs",
    color = "Category",
    size = "Population",
    caption = "Top-ranked states are labeled by abbreviation."
  ) +
  project_theme

source_gap_plot <- state_data |>
  arrange(AFDC_vs_PlugShare_Gap) |>
  slice_head(n = 15) |>
  mutate(State = fct_reorder(State, AFDC_vs_PlugShare_Gap)) |>
  ggplot(aes(x = AFDC_vs_PlugShare_Gap, y = State)) +
  geom_vline(xintercept = 0, linewidth = 0.6, color = "#9CA3AF") +
  geom_col(fill = "#CC79A7", width = 0.72) +
  scale_x_continuous(labels = comma) +
  labs(
    title = "Largest Official vs Consumer-Facing Station Count Gaps",
    subtitle = "Negative values mean PlugShare lists more stations than the official AFDC station count.",
    x = "AFDC station count minus PlugShare station count",
    y = NULL,
    caption = "This chart helps flag differences between official infrastructure records and consumer-facing visibility."
  ) +
  project_theme

economic_readiness_plot <- state_data |>
  ggplot(aes(
    x = Median_Household_Income,
    y = Poverty_Rate,
    color = Opportunity_Category,
    size = EV_Opportunity_Score
  )) +
  geom_point(alpha = 0.78) +
  geom_text(
    data = state_data |> filter(Opportunity_Rank <= 8),
    aes(label = State_Abbr),
    size = 3.2,
    vjust = -0.85,
    show.legend = FALSE
  ) +
  scale_x_continuous(labels = dollar) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  scale_color_manual(values = category_palette) +
  scale_size_continuous(range = c(2.5, 8.5)) +
  guides(
    color = guide_legend(override.aes = list(size = 4), order = 1),
    size = guide_legend(order = 2)
  ) +
  labs(
    title = "Economic Readiness Context",
    subtitle = "Higher income and lower poverty generally support stronger EV market readiness.",
    x = "Median household income",
    y = "Poverty rate",
    color = "Category",
    size = "Opportunity score",
    caption = "Top-ranked states are labeled by abbreviation."
  ) +
  project_theme

component_plot <- state_data |>
  arrange(Opportunity_Rank) |>
  slice_head(n = 10) |>
  select(
    State,
    EV_Adoption_Score,
    Official_Charging_Infrastructure_Score,
    Consumer_Facing_Charging_Visibility_Score,
    Economic_Readiness_Score
  ) |>
  pivot_longer(
    -State,
    names_to = "Component",
    values_to = "Score"
  ) |>
  mutate(
    State = fct_reorder(State, Score, .fun = mean),
    Component = recode(
      Component,
      EV_Adoption_Score = "EV adoption",
      Official_Charging_Infrastructure_Score = "Official charging",
      Consumer_Facing_Charging_Visibility_Score = "Consumer visibility",
      Economic_Readiness_Score = "Economic readiness"
    )
  ) |>
  ggplot(aes(x = State, y = Score, fill = Component)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.68) +
  coord_flip() +
  scale_fill_manual(
    values = c(
      "EV adoption" = "#0072B2",
      "Official charging" = "#009E73",
      "Consumer visibility" = "#CC79A7",
      "Economic readiness" = "#E69F00"
    )
  ) +
  labs(
    title = "What Drives the Top 10 Opportunity Scores?",
    subtitle = "Component scores show whether each state is driven by adoption, infrastructure, visibility, or economics.",
    x = NULL,
    y = "Component score",
    fill = "Score component",
    caption = "Component scores are normalized to a 0-100 scale."
  ) +
  project_theme

save_chart(top_15_plot, "top_15_opportunity_states.png", width = 10, height = 7)
save_chart(adoption_infrastructure_plot, "adoption_vs_charger_availability.png", width = 10, height = 7)
save_chart(source_gap_plot, "afdc_vs_plugshare_gap.png", width = 10, height = 7)
save_chart(economic_readiness_plot, "economic_readiness_context.png", width = 10, height = 7)
save_chart(component_plot, "top_10_component_scores.png", width = 11, height = 7)

# -----------------------------
# Markdown summary report
# -----------------------------

report_lines <- c(
  "# Exploratory Summary",
  "",
  "These tables and charts summarize the final merged EV opportunity dataset produced in R.",
  "",
  "## Score Summary",
  "",
  format_table(score_summary),
  "",
  "## Opportunity Category Summary",
  "",
  format_table(category_summary),
  "",
  "## Top 10 Opportunity States",
  "",
  format_table(top_10_states),
  "",
  "## Bottom 10 Opportunity States",
  "",
  format_table(bottom_10_states),
  "",
  "## Metric Summary",
  "",
  format_table(metric_summary),
  "",
  "## Charts",
  "",
  "- `exploratory/charts/top_15_opportunity_states.png`",
  "- `exploratory/charts/adoption_vs_charger_availability.png`",
  "- `exploratory/charts/afdc_vs_plugshare_gap.png`",
  "- `exploratory/charts/economic_readiness_context.png`",
  "- `exploratory/charts/top_10_component_scores.png`"
)

write_lines(report_lines, report_output_path)

message("Exploratory summaries complete.")
message("Summary tables saved to: ", summary_dir)
message("Charts saved to: ", chart_dir)
message("Markdown report saved to: ", report_output_path)
