# 01_ev_registration_state_pipeline.R
# Pulls state-level EV registration data and saves raw + cleaned files.

source("R/00_setup.R")

# -----------------------------
# Extra package needed for Excel source
# -----------------------------

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl")
}

library(readxl)

# -----------------------------
# Output paths
# -----------------------------

raw_output_path <- file.path(raw_dir, "ev_registration_state_raw.csv")
clean_output_path <- file.path(clean_dir, "ev_registration_state_clean.csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------
# Source
# -----------------------------

ev_source_url <- "https://afdc.energy.gov/files/u/data/data_source/10962/10962-ev-registration-counts-by-state_9-06-24.xlsx?12518e7893="

# -----------------------------
# Download raw Excel file
# -----------------------------

temp_file <- tempfile(fileext = ".xlsx")

download.file(
  url = ev_source_url,
  destfile = temp_file,
  mode = "wb"
)

# The AFDC file has title/header text above the actual table.
# Actual columns begin after the first two rows.
ev_raw <- readxl::read_excel(
  path = temp_file,
  skip = 2
)

# Save raw CSV copy
readr::write_csv(ev_raw, raw_output_path)

# -----------------------------
# Clean data
# -----------------------------

ev_clean <- ev_raw |>
  janitor::clean_names() |>
  rename(
    State = state,
    ev_registration_count = registration_count
  ) |>
  mutate(
    State = str_squish(State),
    ev_registration_count = clean_numeric(ev_registration_count)
  ) |>
  filter(
    !is.na(State),
    State %in% state.name
  ) |>
  left_join(state_lookup, by = "State") |>
  select(
    State,
    State_Abbr,
    ev_registration_count
  ) |>
  arrange(State)

# -----------------------------
# Validation checks
# -----------------------------

if (nrow(ev_clean) != 50) {
  warning("Expected 50 states, but found ", nrow(ev_clean), " rows.")
}

if (any(is.na(ev_clean$ev_registration_count))) {
  warning("Some EV registration counts are missing.")
}

# -----------------------------
# Save cleaned data
# -----------------------------

readr::write_csv(ev_clean, clean_output_path)

message("EV registration state pipeline complete.")
message("Raw file saved to: ", raw_output_path)
message("Clean file saved to: ", clean_output_path)
