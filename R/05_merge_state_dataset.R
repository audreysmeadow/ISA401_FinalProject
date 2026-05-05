# 05_merge_state_dataset.R
# Merge all cleaned state-level datasets.

source("R/00_setup.R")

# -----------------------------
# Input and output paths
# -----------------------------

ev_input_path <- file.path(clean_dir, "ev_registration_state_clean.csv")
afdc_input_path <- file.path(clean_dir, "afdc_charging_state_clean.csv")
census_input_path <- file.path(clean_dir, "census_state_clean.csv")
plugshare_input_path <- file.path(clean_dir, "plugshare_state_clean.csv")

merged_output_path <- file.path(final_dir, "us_ev_state_merged_unscored.csv")

dir.create(final_dir, recursive = TRUE, showWarnings = FALSE)

required_inputs <- c(
  ev_input_path,
  afdc_input_path,
  census_input_path,
  plugshare_input_path
)

missing_inputs <- required_inputs[
  !file.exists(required_inputs) | file.info(required_inputs)$size == 0
]

if (length(missing_inputs) > 0) {
  stop(
    "Missing or empty cleaned input file(s): ",
    paste(missing_inputs, collapse = ", "),
    "\nRun R/01 through R/04 before merging."
  )
}

# -----------------------------
# Read and standardize sources
# -----------------------------

ev_state <- read_csv(ev_input_path, show_col_types = FALSE) |>
  transmute(
    State,
    State_Abbr,
    EV_Count = ev_registration_count,
    EV_Data_Available = !is.na(ev_registration_count)
  )

afdc_state <- read_csv(afdc_input_path, show_col_types = FALSE) |>
  transmute(
    State,
    State_Abbr,
    AFDC_Charging_Station_Count,
    Level2_Charger_Count,
    DC_Fast_Charger_Count,
    Public_Station_Count,
    Private_Station_Count,
    AFDC_Data_Available = !is.na(AFDC_Charging_Station_Count)
  )

census_raw <- read_csv(census_input_path, show_col_types = FALSE)

if (!("average_commute_time" %in% names(census_raw))) {
  census_raw <- census_raw |>
    mutate(average_commute_time = NA_real_)
}

census_state <- census_raw |>
  transmute(
    State,
    State_Abbr,
    Population = total_population,
    Median_Household_Income = median_household_income,
    Per_Capita_Income = per_capita_income,
    Pct_Bachelors_or_Higher = pct_bachelors_or_higher,
    Unemployment_Rate = unemployment_rate,
    Poverty_Rate = poverty_rate,
    Average_Commute_Time = average_commute_time,
    Census_Data_Available = !is.na(total_population)
  )

plugshare_state <- read_csv(plugshare_input_path, show_col_types = FALSE) |>
  transmute(
    State,
    State_Abbr,
    PlugShare_Station_Count,
    PlugShare_Source = Source,
    PlugShare_Scrape_Date = Scrape_Date,
    PlugShare_Data_Available = !is.na(PlugShare_Station_Count)
  )

# -----------------------------
# Merge to one row per state
# -----------------------------

merged_state <- state_lookup |>
  left_join(ev_state, by = c("State", "State_Abbr")) |>
  left_join(afdc_state, by = c("State", "State_Abbr")) |>
  left_join(census_state, by = c("State", "State_Abbr")) |>
  left_join(plugshare_state, by = c("State", "State_Abbr")) |>
  arrange(State)

# -----------------------------
# Validation checks
# -----------------------------

if (nrow(merged_state) != 50) {
  warning("Expected 50 states, but found ", nrow(merged_state), " rows.")
}

if (anyDuplicated(merged_state$State) > 0) {
  warning("Duplicate state rows found in merged data.")
}

source_flags <- c(
  "EV_Data_Available",
  "AFDC_Data_Available",
  "Census_Data_Available",
  "PlugShare_Data_Available"
)

flag_values <- as.data.frame(merged_state[source_flags])

if (any(is.na(flag_values)) || any(flag_values == FALSE, na.rm = TRUE)) {
  warning("One or more states did not join cleanly across all sources.")
}

# -----------------------------
# Save merged output
# -----------------------------

write_csv(merged_state, merged_output_path)

message("State dataset merge complete.")
message("Merged file saved to: ", merged_output_path)
