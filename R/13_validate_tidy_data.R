# 13_validate_tidy_data.R
# Validate that clean, final, and dashboard-ready files have clear tidy row grains.

source("R/00_setup.R")

validation_output_path <- file.path(validation_dir, "tidy_data_validation.csv")
tidy_notes_path <- file.path(docs_dir, "tidy_data_notes.md")

dir.create(validation_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(docs_dir, recursive = TRUE, showWarnings = FALSE)

tidy_checks <- tribble(
  ~Dataset, ~File, ~Row_Grain, ~Key_Columns,
  "EV registrations by state",
  file.path(clean_dir, "ev_registration_state_clean.csv"),
  "One row per U.S. state",
  list(c("State", "State_Abbr")),
  "AFDC charging stations by state",
  file.path(clean_dir, "afdc_charging_state_clean.csv"),
  "One row per U.S. state",
  list(c("State", "State_Abbr")),
  "AFDC charging station locations",
  file.path(clean_dir, "afdc_charging_station_clean.csv"),
  "One row per physical charging station",
  list(c("Station_ID")),
  "Census ACS state context",
  file.path(clean_dir, "census_state_clean.csv"),
  "One row per U.S. state",
  list(c("State", "State_Abbr")),
  "AAA gas prices by state",
  file.path(clean_dir, "aaa_state_gas_prices_clean.csv"),
  "One row per U.S. state",
  list(c("State", "State_Abbr")),
  "AFDC station spacing by state",
  file.path(final_dir, "afdc_charging_station_distance_summary.csv"),
  "One row per U.S. state",
  list(c("State", "State_Abbr")),
  "Final state analysis dashboard dataset",
  file.path(final_dir, "ev_state_analysis_final.csv"),
  "One row per U.S. state",
  list(c("State", "State_Abbr"))
)

check_tidy_file <- function(Dataset, File, Row_Grain, Key_Columns) {
  Key_Columns <- unlist(Key_Columns)

  if (!file.exists(File)) {
    return(tibble(
      Dataset = Dataset,
      File = File,
      Row_Grain = Row_Grain,
      Key_Columns = paste(Key_Columns, collapse = ", "),
      Row_Count = NA_integer_,
      Column_Count = NA_integer_,
      File_Exists = FALSE,
      Missing_Key_Columns = paste(Key_Columns, collapse = ", "),
      Rows_With_Missing_Key = NA_integer_,
      Duplicate_Key_Rows = NA_integer_,
      Tidy_Check = "REVIEW"
    ))
  }

  data <- read_csv(File, show_col_types = FALSE)
  missing_key_columns <- setdiff(Key_Columns, names(data))

  if (length(missing_key_columns) > 0) {
    rows_with_missing_key <- NA_integer_
    duplicate_key_rows <- NA_integer_
  } else {
    key_data <- data |>
      select(all_of(Key_Columns))

    rows_with_missing_key <- key_data |>
      filter(if_any(everything(), ~ is.na(.x) | str_squish(as.character(.x)) == "")) |>
      nrow()

    duplicate_key_rows <- data |>
      count(across(all_of(Key_Columns)), name = "key_count") |>
      filter(key_count > 1) |>
      summarise(duplicate_rows = sum(key_count), .groups = "drop") |>
      pull(duplicate_rows)

    if (length(duplicate_key_rows) == 0 || is.na(duplicate_key_rows)) {
      duplicate_key_rows <- 0L
    }
  }

  tidy_check <- if (
    length(missing_key_columns) == 0 &&
      rows_with_missing_key == 0 &&
      duplicate_key_rows == 0
  ) {
    "PASS"
  } else {
    "REVIEW"
  }

  tibble(
    Dataset = Dataset,
    File = File,
    Row_Grain = Row_Grain,
    Key_Columns = paste(Key_Columns, collapse = ", "),
    Row_Count = nrow(data),
    Column_Count = ncol(data),
    File_Exists = TRUE,
    Missing_Key_Columns = paste(missing_key_columns, collapse = ", "),
    Rows_With_Missing_Key = rows_with_missing_key,
    Duplicate_Key_Rows = duplicate_key_rows,
    Tidy_Check = tidy_check
  )
}

tidy_validation <- pmap_dfr(tidy_checks, check_tidy_file)

write_csv(tidy_validation, validation_output_path)

tidy_notes <- c(
  "# Tidy Data Notes",
  "",
  "Raw files are kept close to the acquired source format for auditability.",
  "The clean, final, and dashboard-ready files are organized as tidy analysis tables:",
  "",
  "- state-level files use one row per U.S. state and one variable per column;",
  "- the AFDC station location file uses one row per physical charging station;",
  "- the final dashboard state file merges the state-level sources into one row per state;",
  "- station locations stay separate because their row grain is station-level, not state-level.",
  "",
  "Validation output:",
  paste0("- `", validation_output_path, "`")
)

write_lines(tidy_notes, tidy_notes_path)

message("Tidy data validation complete: ", validation_output_path)
message("Tidy data notes complete: ", tidy_notes_path)
