# 06_calculate_scores.R
# Calculate normalized metrics, opportunity scores, rankings, and categories.

source("R/00_setup.R")

# -----------------------------
# Input and output paths
# -----------------------------

merged_input_path <- file.path(final_dir, "us_ev_state_merged_unscored.csv")
final_output_path <- file.path(final_dir, "us_ev_state_final.csv")

if (!file.exists(merged_input_path) || file.info(merged_input_path)$size == 0) {
  stop("Missing merged dataset. Run R/05_merge_state_dataset.R first.")
}

state_data <- read_csv(merged_input_path, show_col_types = FALSE)

required_columns <- c(
  "State",
  "State_Abbr",
  "EV_Count",
  "Population",
  "Median_Household_Income",
  "Poverty_Rate",
  "AFDC_Charging_Station_Count",
  "Level2_Charger_Count",
  "DC_Fast_Charger_Count",
  "PlugShare_Station_Count"
)

missing_columns <- setdiff(required_columns, names(state_data))

if (length(missing_columns) > 0) {
  stop(
    "Merged dataset is missing required column(s): ",
    paste(missing_columns, collapse = ", ")
  )
}

# -----------------------------
# Calculate rates and component scores
# -----------------------------

scored_state <- state_data |>
  mutate(
    Official_Charger_Count =
      Level2_Charger_Count + DC_Fast_Charger_Count,

    EVs_Per_10000_Residents =
      safe_divide(EV_Count, Population, 10000),

    Chargers_Per_1000_EVs =
      safe_divide(Official_Charger_Count, EV_Count, 1000),

    PlugShare_Per_10000_Residents =
      safe_divide(PlugShare_Station_Count, Population, 10000),

    AFDC_vs_PlugShare_Gap =
      AFDC_Charging_Station_Count - PlugShare_Station_Count,

    EV_Adoption_Score =
      scale_0_100(EVs_Per_10000_Residents),

    Official_Charging_Infrastructure_Score =
      scale_0_100(Chargers_Per_1000_EVs),

    Consumer_Facing_Charging_Visibility_Score =
      scale_0_100(PlugShare_Per_10000_Residents),

    Median_Income_Score =
      scale_0_100(Median_Household_Income),

    Population_Score =
      scale_0_100(Population),

    Poverty_Rate_Score =
      100 - scale_0_100(Poverty_Rate),

    Economic_Readiness_Score =
      0.40 * Median_Income_Score +
      0.30 * Population_Score +
      0.30 * Poverty_Rate_Score,

    EV_Opportunity_Score_Raw =
      0.35 * EV_Adoption_Score +
      0.25 * Official_Charging_Infrastructure_Score +
      0.15 * Consumer_Facing_Charging_Visibility_Score +
      0.25 * Economic_Readiness_Score
  ) |>
  arrange(desc(EV_Opportunity_Score_Raw), State) |>
  mutate(
    Opportunity_Rank = row_number(),
    Opportunity_Tier = ntile(desc(EV_Opportunity_Score_Raw), 3),
    Opportunity_Category = case_when(
      Opportunity_Tier == 1 ~ "High",
      Opportunity_Tier == 2 ~ "Medium",
      Opportunity_Tier == 3 ~ "Low",
      TRUE ~ NA_character_
    )
  ) |>
  mutate(
    across(
      c(
        EVs_Per_10000_Residents,
        Chargers_Per_1000_EVs,
        PlugShare_Per_10000_Residents,
        AFDC_vs_PlugShare_Gap,
        EV_Adoption_Score,
        Official_Charging_Infrastructure_Score,
        Consumer_Facing_Charging_Visibility_Score,
        Median_Income_Score,
        Population_Score,
        Poverty_Rate_Score,
        Economic_Readiness_Score,
        EV_Opportunity_Score_Raw
      ),
      ~ round(.x, 2)
    ),
    Average_Commute_Time = round(Average_Commute_Time, 2),
    EV_Opportunity_Score = EV_Opportunity_Score_Raw
  ) |>
  select(
    State,
    State_Abbr,
    EV_Count,
    Population,
    Median_Household_Income,
    Per_Capita_Income,
    Pct_Bachelors_or_Higher,
    Unemployment_Rate,
    Poverty_Rate,
    Average_Commute_Time,
    AFDC_Charging_Station_Count,
    Official_Charger_Count,
    Level2_Charger_Count,
    DC_Fast_Charger_Count,
    Public_Station_Count,
    Private_Station_Count,
    PlugShare_Station_Count,
    EVs_Per_10000_Residents,
    Chargers_Per_1000_EVs,
    PlugShare_Per_10000_Residents,
    AFDC_vs_PlugShare_Gap,
    EV_Adoption_Score,
    Official_Charging_Infrastructure_Score,
    Consumer_Facing_Charging_Visibility_Score,
    Median_Income_Score,
    Population_Score,
    Poverty_Rate_Score,
    Economic_Readiness_Score,
    EV_Opportunity_Score,
    Opportunity_Rank,
    Opportunity_Category,
    EV_Data_Available,
    AFDC_Data_Available,
    Census_Data_Available,
    PlugShare_Data_Available,
    PlugShare_Source,
    PlugShare_Scrape_Date
  )

# -----------------------------
# Save scored final output
# -----------------------------

write_csv(scored_state, final_output_path)

message("EV opportunity scoring complete.")
message("Final scored file saved to: ", final_output_path)
