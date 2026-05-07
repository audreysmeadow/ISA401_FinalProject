# 01_ev_registration_state_pipeline.R
# Pull state-level EV registration data.

source("R/00_setup.R")

raw_output_path <- file.path(raw_dir, "ev_registration_state_raw.csv")
clean_output_path <- file.path(clean_dir, "ev_registration_state_clean.csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

ev_source_url <- "https://afdc.energy.gov/files/u/data/data_source/10962/10962-ev-registration-counts-by-state_9-06-24.xlsx?12518e7893="
temp_file <- tempfile(fileext = ".xlsx")

download.file(ev_source_url, temp_file, mode = "wb")

ev_raw <- readxl::read_excel(temp_file, skip = 2)
write_csv(ev_raw, raw_output_path)

ev_clean <- ev_raw |>
  clean_names() |>
  rename(
    State = state,
    EV_Count = registration_count
  ) |>
  mutate(
    State = str_squish(State),
    EV_Count = clean_numeric(EV_Count)
  ) |>
  filter(State %in% state.name) |>
  left_join(state_lookup, by = "State") |>
  select(State, State_Abbr, EV_Count) |>
  arrange(State)

write_csv(ev_clean, clean_output_path)

message("EV registration pipeline complete: ", clean_output_path)
