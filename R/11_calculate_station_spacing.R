# 11_calculate_station_spacing.R
# Calculate average nearest-neighbor distance between AFDC charging stations by state.

source("R/00_setup.R")

station_input_path <- file.path(clean_dir, "afdc_charging_station_clean.csv")
distance_output_path <- file.path(final_dir, "afdc_charging_station_distance_summary.csv")
dashboard_distance_output_path <- file.path(dashboard_dir, "afdc_charging_station_distance_summary.csv")

dir.create(final_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dashboard_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(station_input_path) || file.info(station_input_path)$size == 0) {
  stop("Missing station-level AFDC file. Run R/02_afdc_charging_pipeline.R first.")
}

stations <- read_csv(station_input_path, show_col_types = FALSE) |>
  filter(!is.na(Latitude), !is.na(Longitude))

nearest_by_state <- stations |>
  group_by(State, State_Abbr) |>
  group_modify(~ {
    state_stations <- .x |>
      mutate(row_id = row_number())

    if (nrow(state_stations) < 2) {
      return(tibble(
        Station_ID = state_stations$Station_ID,
        Nearest_Station_ID = NA_character_,
        Nearest_Station_Distance_Miles = NA_real_
      ))
    }

    coords <- lonlat_to_unit_sphere(
      latitude = state_stations$Latitude,
      longitude = state_stations$Longitude
    )

    nearest <- RANN::nn2(data = coords, query = coords, k = 2)
    nearest_index <- nearest$nn.idx[, 2]

    tibble(
      Station_ID = state_stations$Station_ID,
      Nearest_Station_ID = state_stations$Station_ID[nearest_index],
      Nearest_Station_Distance_Miles = haversine_miles(
        lat1 = state_stations$Latitude,
        lon1 = state_stations$Longitude,
        lat2 = state_stations$Latitude[nearest_index],
        lon2 = state_stations$Longitude[nearest_index]
      )
    )
  }) |>
  ungroup()

distance_summary <- stations |>
  select(State, State_Abbr, Station_ID) |>
  left_join(nearest_by_state, by = c("State", "State_Abbr", "Station_ID")) |>
  group_by(State, State_Abbr) |>
  summarise(
    Station_Count = n(),
    Stations_With_Nearest_Neighbor = sum(!is.na(Nearest_Station_Distance_Miles)),
    Average_Nearest_Station_Distance_Miles = round(mean(Nearest_Station_Distance_Miles, na.rm = TRUE), 2),
    Median_Nearest_Station_Distance_Miles = round(median(Nearest_Station_Distance_Miles, na.rm = TRUE), 2),
    Min_Nearest_Station_Distance_Miles = round(min(Nearest_Station_Distance_Miles, na.rm = TRUE), 2),
    Max_Nearest_Station_Distance_Miles = round(max(Nearest_Station_Distance_Miles, na.rm = TRUE), 2),
    .groups = "drop"
  ) |>
  mutate(
    across(
      c(
        Average_Nearest_Station_Distance_Miles,
        Median_Nearest_Station_Distance_Miles,
        Min_Nearest_Station_Distance_Miles,
        Max_Nearest_Station_Distance_Miles
      ),
      ~ if_else(is.nan(.x) | is.infinite(.x), NA_real_, .x)
    )
  ) |>
  arrange(State)

write_csv(distance_summary, distance_output_path)
write_csv(distance_summary, dashboard_distance_output_path)

message("Station spacing summary complete.")
message("Final file: ", distance_output_path)
message("Dashboard file: ", dashboard_distance_output_path)
