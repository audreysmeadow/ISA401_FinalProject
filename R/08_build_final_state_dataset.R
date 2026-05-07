# 08_build_final_state_dataset.R
# Build the main tidy state-level dataset for dashboarding.

source("R/00_setup.R")

ev_path <- file.path(clean_dir, "ev_registration_state_clean.csv")
charging_state_path <- file.path(clean_dir, "afdc_charging_state_clean.csv")
census_path <- file.path(clean_dir, "census_state_clean.csv")
gas_path <- file.path(clean_dir, "aaa_state_gas_prices_clean.csv")
distance_path <- file.path(final_dir, "afdc_charging_station_distance_summary.csv")

final_output_path <- file.path(final_dir, "ev_state_analysis_final.csv")
dashboard_output_path <- file.path(dashboard_dir, "ev_state_analysis_final.csv")

dir.create(final_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dashboard_dir, recursive = TRUE, showWarnings = FALSE)

required_inputs <- c(
  ev_path,
  charging_state_path,
  census_path,
  gas_path,
  distance_path
)

missing_inputs <- required_inputs[!file.exists(required_inputs)]

if (length(missing_inputs) > 0) {
  stop(
    "Missing required input files for final state dataset: ",
    paste(missing_inputs, collapse = ", ")
  )
}

ev_state <- read_csv(ev_path, show_col_types = FALSE)
charging_state <- read_csv(charging_state_path, show_col_types = FALSE)
census_state <- read_csv(census_path, show_col_types = FALSE)
gas_state <- read_csv(gas_path, show_col_types = FALSE)
distance_state <- read_csv(distance_path, show_col_types = FALSE) |>
  select(
    State,
    State_Abbr,
    Station_Count,
    Stations_With_Nearest_Neighbor,
    Average_Nearest_Station_Distance_Miles,
    Median_Nearest_Station_Distance_Miles,
    Min_Nearest_Station_Distance_Miles,
    Max_Nearest_Station_Distance_Miles
  )

state_analysis_final <- ev_state |>
  full_join(charging_state, by = c("State", "State_Abbr")) |>
  full_join(census_state, by = c("State", "State_Abbr")) |>
  full_join(gas_state, by = c("State", "State_Abbr")) |>
  full_join(distance_state, by = c("State", "State_Abbr")) |>
  filter(State %in% state.name) |>
  mutate(
    EVs_Per_100k_People = safe_divide(EV_Count, total_population, 100000),
    Charging_Stations_Per_100k_People = safe_divide(
      AFDC_Charging_Station_Count,
      total_population,
      100000
    ),
    EVs_Per_Charging_Station = safe_divide(EV_Count, AFDC_Charging_Station_Count),
    DC_Fast_Charger_Share = safe_divide(
      DC_Fast_Charger_Count,
      Level2_Charger_Count + DC_Fast_Charger_Count,
      100
    ),
    Public_Station_Share = safe_divide(Public_Station_Count, AFDC_Charging_Station_Count, 100)
  ) |>
  select(
    State,
    State_Abbr,
    EV_Count,
    AFDC_Charging_Station_Count,
    Level2_Charger_Count,
    DC_Fast_Charger_Count,
    Public_Station_Count,
    Private_Station_Count,
    total_population,
    total_population_moe,
    median_household_income,
    median_household_income_moe,
    per_capita_income,
    per_capita_income_moe,
    poverty_universe,
    poverty_universe_moe,
    poverty_count,
    poverty_count_moe,
    poverty_rate,
    aggregate_travel_time_minutes,
    aggregate_travel_time_minutes_moe,
    workers_with_commute,
    workers_with_commute_moe,
    average_commute_time,
    Regular_Gas_Price,
    Mid_Grade_Gas_Price,
    Premium_Gas_Price,
    Diesel_Gas_Price,
    Gas_Price_Date,
    Station_Count,
    Stations_With_Nearest_Neighbor,
    Average_Nearest_Station_Distance_Miles,
    Median_Nearest_Station_Distance_Miles,
    Min_Nearest_Station_Distance_Miles,
    Max_Nearest_Station_Distance_Miles,
    EVs_Per_100k_People,
    Charging_Stations_Per_100k_People,
    EVs_Per_Charging_Station,
    DC_Fast_Charger_Share,
    Public_Station_Share
  ) |>
  arrange(State)

write_csv(state_analysis_final, final_output_path)
write_csv(state_analysis_final, dashboard_output_path)

message("Final state dataset complete: ", final_output_path)
message("Dashboard file: ", dashboard_output_path)
