# 03_census_state_pipeline.R
# Pulls state-level ACS/Census variables and saves raw + cleaned files.

source("R/00_setup.R")

# -----------------------------
# Output paths
# -----------------------------

raw_output_path <- file.path(raw_dir, "census_state_raw.csv")
clean_output_path <- file.path(clean_dir, "census_state_clean.csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------
# Census settings
# -----------------------------

acs_year <- 2022
acs_survey <- "acs5"

# Variables:
# B01003_001 = Total population
# B19013_001 = Median household income
# B19301_001 = Per capita income
# B15003_001 = Population age 25+ educational attainment universe
# B15003_022 = Bachelor's degree
# B15003_023 = Master's degree
# B15003_024 = Professional school degree
# B15003_025 = Doctorate degree
# B23025_003 = Civilian labor force
# B23025_004 = Employed
# B23025_005 = Unemployed
# B17001_001 = Poverty status universe
# B17001_002 = Income below poverty level
# B08013_001 = Aggregate travel time to work in minutes
# B08303_001 = Workers with a reported commute time

census_variables <- c(
  total_population = "B01003_001",
  median_household_income = "B19013_001",
  per_capita_income = "B19301_001",

  education_25_plus_total = "B15003_001",
  bachelors_degree = "B15003_022",
  masters_degree = "B15003_023",
  professional_degree = "B15003_024",
  doctorate_degree = "B15003_025",

  civilian_labor_force = "B23025_003",
  employed_population = "B23025_004",
  unemployed_population = "B23025_005",

  poverty_universe = "B17001_001",
  poverty_count = "B17001_002",

  aggregate_travel_time_minutes = "B08013_001",
  workers_with_commute = "B08303_001"
)

# -----------------------------
# Pull ACS data
# -----------------------------

census_raw <- tidycensus::get_acs(
  geography = "state",
  variables = census_variables,
  year = acs_year,
  survey = acs_survey,
  output = "wide"
)

# Save raw CSV copy
readr::write_csv(census_raw, raw_output_path)

# -----------------------------
# Clean data
# -----------------------------

census_clean <- census_raw |>
  janitor::clean_names() |>
  rename(
    State = name,
    total_population = total_population_e,
    total_population_moe = total_population_m,
    median_household_income = median_household_income_e,
    median_household_income_moe = median_household_income_m,
    per_capita_income = per_capita_income_e,
    per_capita_income_moe = per_capita_income_m,
    education_25_plus_total = education_25_plus_total_e,
    bachelors_degree = bachelors_degree_e,
    masters_degree = masters_degree_e,
    professional_degree = professional_degree_e,
    doctorate_degree = doctorate_degree_e,
    civilian_labor_force = civilian_labor_force_e,
    employed_population = employed_population_e,
    unemployed_population = unemployed_population_e,
    poverty_universe = poverty_universe_e,
    poverty_count = poverty_count_e,
    aggregate_travel_time_minutes = aggregate_travel_time_minutes_e,
    workers_with_commute = workers_with_commute_e
  ) |>
  mutate(
    State = str_squish(State),

    bachelors_or_higher_count =
      bachelors_degree +
      masters_degree +
      professional_degree +
      doctorate_degree,

    pct_bachelors_or_higher =
      100 * bachelors_or_higher_count / education_25_plus_total,

    unemployment_rate =
      100 * unemployed_population / civilian_labor_force,

    poverty_rate =
      100 * poverty_count / poverty_universe,

    average_commute_time =
      aggregate_travel_time_minutes / workers_with_commute
  ) |>
  left_join(state_lookup, by = "State") |>
  filter(State %in% state.name) |>
  select(
    State,
    State_Abbr,

    total_population,
    median_household_income,
    per_capita_income,

    education_25_plus_total,
    bachelors_or_higher_count,
    pct_bachelors_or_higher,

    civilian_labor_force,
    employed_population,
    unemployed_population,
    unemployment_rate,

    poverty_universe,
    poverty_count,
    poverty_rate,

    workers_with_commute,
    aggregate_travel_time_minutes,
    average_commute_time,

    total_population_moe,
    median_household_income_moe,
    per_capita_income_moe
  ) |>
  arrange(State)

# -----------------------------
# Validation checks
# -----------------------------

if (nrow(census_clean) != 50) {
  warning("Expected 50 states, but found ", nrow(census_clean), " rows.")
}

if (any(is.na(census_clean$State_Abbr))) {
  warning("Some states are missing abbreviations.")
}

if (any(is.na(census_clean$total_population))) {
  warning("Some states are missing population data.")
}

# -----------------------------
# Save cleaned data
# -----------------------------

readr::write_csv(census_clean, clean_output_path)

message("Census state pipeline complete.")
message("Raw file saved to: ", raw_output_path)
message("Clean file saved to: ", clean_output_path)
