# 03_census_state_pipeline.R
# Pull state-level ACS demographic and economic data.

source("R/00_setup.R")

raw_output_path <- file.path(raw_dir, "census_state_raw.csv")
clean_output_path <- file.path(clean_dir, "census_state_clean.csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

census_variables <- c(
  total_population = "B01003_001",
  median_household_income = "B19013_001",
  per_capita_income = "B19301_001",
  poverty_universe = "B17001_001",
  poverty_count = "B17001_002",
  aggregate_travel_time_minutes = "B08013_001",
  workers_with_commute = "B08303_001"
)

census_raw <- get_acs(
  geography = "state",
  variables = census_variables,
  year = 2022,
  survey = "acs5",
  output = "wide"
)

write_csv(census_raw, raw_output_path)

census_clean <- census_raw |>
  clean_names() |>
  transmute(
    Census_GEOID = geoid,
    State = str_squish(name),
    total_population = total_population_e,
    total_population_moe = total_population_m,
    median_household_income = median_household_income_e,
    median_household_income_moe = median_household_income_m,
    per_capita_income = per_capita_income_e,
    per_capita_income_moe = per_capita_income_m,
    poverty_universe = poverty_universe_e,
    poverty_universe_moe = poverty_universe_m,
    poverty_count = poverty_count_e,
    poverty_count_moe = poverty_count_m,
    poverty_rate = safe_divide(poverty_count_e, poverty_universe_e, 100),
    aggregate_travel_time_minutes = aggregate_travel_time_minutes_e,
    aggregate_travel_time_minutes_moe = aggregate_travel_time_minutes_m,
    workers_with_commute = workers_with_commute_e,
    workers_with_commute_moe = workers_with_commute_m,
    average_commute_time = safe_divide(aggregate_travel_time_minutes_e, workers_with_commute_e)
  ) |>
  left_join(state_lookup, by = "State") |>
  filter(State %in% state.name) |>
  select(State, State_Abbr, everything()) |>
  arrange(State)

write_csv(census_clean, clean_output_path)

message("Census pipeline complete: ", clean_output_path)
