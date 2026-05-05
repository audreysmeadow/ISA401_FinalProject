# 07_validate_dataset.R
# Validate the final merged dataset and create validation tables.

source("R/00_setup.R")

# -----------------------------
# Input and output paths
# -----------------------------

final_input_path <- file.path(final_dir, "us_ev_state_final.csv")
validation_results_path <- file.path(validation_dir, "validation_results.csv")
validation_summary_path <- file.path(validation_dir, "validation_summary.csv")

dir.create(validation_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(final_input_path) || file.info(final_input_path)$size == 0) {
  stop("Missing final scored dataset. Run R/06_calculate_scores.R first.")
}

final_state <- read_csv(final_input_path, show_col_types = FALSE)

required_fields <- c(
  "State",
  "State_Abbr",
  "EV_Count",
  "Population",
  "Median_Household_Income",
  "Poverty_Rate",
  "AFDC_Charging_Station_Count",
  "Level2_Charger_Count",
  "DC_Fast_Charger_Count",
  "PlugShare_Station_Count",
  "EVs_Per_10000_Residents",
  "Chargers_Per_1000_EVs",
  "PlugShare_Per_10000_Residents",
  "EV_Opportunity_Score",
  "Opportunity_Rank",
  "Opportunity_Category"
)

missing_fields <- setdiff(required_fields, names(final_state))

if (length(missing_fields) > 0) {
  stop(
    "Final dataset is missing required field(s): ",
    paste(missing_fields, collapse = ", ")
  )
}

# -----------------------------
# Issue-level validation table
# -----------------------------

empty_issues <- tibble(
  State = character(),
  Check_Name = character(),
  Issue_Type = character(),
  Field = character(),
  Value = character(),
  Severity = character(),
  Notes = character()
)

expected_state_issues <- state_lookup |>
  anti_join(final_state |> select(State, State_Abbr), by = c("State", "State_Abbr")) |>
  transmute(
    State,
    Check_Name = "Expected 50 states",
    Issue_Type = "Missing row",
    Field = "State",
    Value = State,
    Severity = "High",
    Notes = "State from the standard lookup table is missing from the final dataset."
  )

row_count_issue <- if (nrow(final_state) == 50) {
  empty_issues
} else {
  tibble(
    State = NA_character_,
    Check_Name = "Expected 50 states",
    Issue_Type = "Invalid row count",
    Field = "row_count",
    Value = as.character(nrow(final_state)),
    Severity = "High",
    Notes = "The final dataset should contain exactly one row for each of the 50 states."
  )
}

missing_state_issues <- final_state |>
  filter(is.na(State) | str_squish(State) == "" | is.na(State_Abbr) | str_squish(State_Abbr) == "") |>
  transmute(
    State,
    Check_Name = "Missing state",
    Issue_Type = "Missing value",
    Field = if_else(is.na(State) | str_squish(State) == "", "State", "State_Abbr"),
    Value = NA_character_,
    Severity = "High",
    Notes = "State and State_Abbr cannot be blank."
  )

duplicate_state_issues <- final_state |>
  add_count(State, name = "state_row_count") |>
  filter(!is.na(State), state_row_count > 1) |>
  transmute(
    State,
    Check_Name = "Duplicate state rows",
    Issue_Type = "Duplicate row",
    Field = "State",
    Value = as.character(state_row_count),
    Severity = "High",
    Notes = "Each state should appear once in the final dataset."
  ) |>
  distinct()

ev_count_issues <- final_state |>
  filter(is.na(EV_Count) | EV_Count < 0) |>
  transmute(
    State,
    Check_Name = "Invalid EV count",
    Issue_Type = "Invalid value",
    Field = "EV_Count",
    Value = as.character(EV_Count),
    Severity = "High",
    Notes = "EV_Count must be greater than or equal to zero."
  )

population_issues <- final_state |>
  filter(is.na(Population) | Population <= 0) |>
  transmute(
    State,
    Check_Name = "Invalid population",
    Issue_Type = "Invalid value",
    Field = "Population",
    Value = as.character(Population),
    Severity = "High",
    Notes = "Population must be greater than zero."
  )

income_issues <- final_state |>
  filter(is.na(Median_Household_Income) | Median_Household_Income <= 0) |>
  transmute(
    State,
    Check_Name = "Invalid income",
    Issue_Type = "Invalid value",
    Field = "Median_Household_Income",
    Value = as.character(Median_Household_Income),
    Severity = "High",
    Notes = "Median household income must be greater than zero."
  )

charger_fields <- c(
  "AFDC_Charging_Station_Count",
  "Official_Charger_Count",
  "Level2_Charger_Count",
  "DC_Fast_Charger_Count",
  "Public_Station_Count",
  "Private_Station_Count",
  "PlugShare_Station_Count"
)

charger_count_issues <- final_state |>
  select(State, all_of(charger_fields)) |>
  pivot_longer(-State, names_to = "Field", values_to = "Value") |>
  filter(is.na(Value) | Value < 0) |>
  transmute(
    State,
    Check_Name = "Invalid charger count",
    Issue_Type = "Invalid value",
    Field,
    Value = as.character(Value),
    Severity = "High",
    Notes = "Charging station and charger counts must be greater than or equal to zero."
  )

source_flag_fields <- c(
  "EV_Data_Available",
  "AFDC_Data_Available",
  "Census_Data_Available",
  "PlugShare_Data_Available"
)

failed_join_issues <- final_state |>
  select(State, all_of(source_flag_fields)) |>
  pivot_longer(-State, names_to = "Field", values_to = "Value") |>
  filter(is.na(Value) | Value != TRUE) |>
  transmute(
    State,
    Check_Name = "Failed joins",
    Issue_Type = "Failed join",
    Field,
    Value = as.character(Value),
    Severity = "High",
    Notes = "Every state should join across EV registration, AFDC, Census, and PlugShare sources."
  )

rate_fields <- c(
  "EVs_Per_10000_Residents",
  "Chargers_Per_1000_EVs",
  "PlugShare_Per_10000_Residents"
)

division_issues <- final_state |>
  select(State, all_of(rate_fields)) |>
  pivot_longer(-State, names_to = "Field", values_to = "Value") |>
  filter(is.infinite(Value) | is.nan(Value)) |>
  transmute(
    State,
    Check_Name = "Division errors",
    Issue_Type = "Calculation error",
    Field,
    Value = as.character(Value),
    Severity = "High",
    Notes = "Rate calculations should not produce infinite or NaN values."
  )

score_fields <- c(
  "EV_Adoption_Score",
  "Official_Charging_Infrastructure_Score",
  "Consumer_Facing_Charging_Visibility_Score",
  "Economic_Readiness_Score",
  "EV_Opportunity_Score"
)

score_issues <- final_state |>
  select(State, all_of(score_fields)) |>
  pivot_longer(-State, names_to = "Field", values_to = "Value") |>
  filter(is.na(Value) | Value < 0 | Value > 100) |>
  transmute(
    State,
    Check_Name = "Score range",
    Issue_Type = "Invalid score",
    Field,
    Value = as.character(Value),
    Severity = "Medium",
    Notes = "Score fields should fall within the 0 to 100 range."
  )

validation_results <- bind_rows(
  expected_state_issues,
  row_count_issue,
  missing_state_issues,
  duplicate_state_issues,
  ev_count_issues,
  population_issues,
  income_issues,
  charger_count_issues,
  failed_join_issues,
  division_issues,
  score_issues
) |>
  arrange(desc(Severity), Check_Name, State, Field)

# -----------------------------
# Check-level validation summary
# -----------------------------

check_definitions <- tribble(
  ~Check_Name, ~Rule, ~Severity,
  "Expected 50 states", "The final dataset should contain exactly one row for each of the 50 states.", "High",
  "Missing state", "State and State_Abbr cannot be blank.", "High",
  "Duplicate state rows", "Each state should appear once.", "High",
  "Invalid EV count", "EV_Count must be greater than or equal to zero.", "High",
  "Invalid population", "Population must be greater than zero.", "High",
  "Invalid income", "Median household income must be greater than zero.", "High",
  "Invalid charger count", "Charging station counts must be greater than or equal to zero.", "High",
  "Failed joins", "Every state should join across EV, charging, Census, and PlugShare sources.", "High",
  "Division errors", "Rate calculations should not produce infinite or NaN values.", "High",
  "Score range", "EV_Opportunity_Score and component scores should fall between 0 and 100.", "Medium"
)

validation_summary <- check_definitions |>
  left_join(
    validation_results |>
      count(Check_Name, name = "Issue_Count"),
    by = "Check_Name"
  ) |>
  mutate(
    Issue_Count = replace_na(Issue_Count, 0),
    Status = if_else(Issue_Count == 0, "Pass", "Review"),
    Run_Date = Sys.Date()
  ) |>
  select(Run_Date, Check_Name, Rule, Severity, Status, Issue_Count)

# -----------------------------
# Save validation outputs
# -----------------------------

write_csv(validation_results, validation_results_path)
write_csv(validation_summary, validation_summary_path)

message("Validation complete.")
message("Issue-level validation file saved to: ", validation_results_path)
message("Summary validation file saved to: ", validation_summary_path)
