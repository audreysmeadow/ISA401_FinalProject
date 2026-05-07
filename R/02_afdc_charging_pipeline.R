# 02_afdc_charging_pipeline.R
# Pull AFDC station data and create state and station-level clean files.

source("R/00_setup.R")

raw_output_path <- file.path(raw_dir, "afdc_charging_raw.csv")
state_clean_output_path <- file.path(clean_dir, "afdc_charging_state_clean.csv")
station_clean_output_path <- file.path(clean_dir, "afdc_charging_station_clean.csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

afdc_request <- request(AFDC_BASE_URL) |>
  req_url_query(
    api_key = AFDC_API_KEY,
    fuel_type = "ELEC",
    country = "US",
    status = "E",
    limit = "all"
  )

afdc_response <- req_perform(afdc_request)
afdc_json <- resp_body_json(afdc_response, simplifyVector = TRUE)
afdc_raw <- as_tibble(afdc_json$fuel_stations)

afdc_raw_flat <- afdc_raw |>
  clean_names() |>
  select(
    any_of(c(
      "id", "station_name", "street_address", "city", "state", "zip",
      "country", "status_code", "access_code", "fuel_type_code",
      "ev_level2_evse_num", "ev_dc_fast_num", "ev_network",
      "latitude", "longitude", "date_last_confirmed", "open_date",
      "updated_at", "owner_type_code", "facility_type"
    ))
  ) |>
  mutate(
    across(where(is.character), ~ str_squish(str_replace_all(.x, "[\r\n]+", " ")))
  )

write_csv(afdc_raw_flat, raw_output_path)

afdc_charging_station_clean <- afdc_raw_flat |>
  filter(
    state %in% state.abb,
    country == "US",
    !is.na(latitude),
    !is.na(longitude)
  ) |>
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude),
    ev_level2_evse_num = replace_na(as.numeric(ev_level2_evse_num), 0),
    ev_dc_fast_num = replace_na(as.numeric(ev_dc_fast_num), 0),
    total_evse_count = ev_level2_evse_num + ev_dc_fast_num,
    station_access_type = str_to_title(access_code),
    station_status = case_when(
      status_code == "E" ~ "Available",
      status_code == "P" ~ "Planned",
      status_code == "T" ~ "Temporarily Unavailable",
      TRUE ~ status_code
    )
  ) |>
  left_join(state_lookup, by = c("state" = "State_Abbr")) |>
  transmute(
    Station_ID = id,
    Station_Name = station_name,
    Street_Address = street_address,
    City = city,
    State,
    State_Abbr = state,
    ZIP = zip,
    Latitude = latitude,
    Longitude = longitude,
    Access_Type = station_access_type,
    Station_Status = station_status,
    EV_Network = ev_network,
    Level2_Charger_Count = ev_level2_evse_num,
    DC_Fast_Charger_Count = ev_dc_fast_num,
    Total_EVSE_Count = total_evse_count,
    Owner_Type_Code = owner_type_code,
    Facility_Type = facility_type,
    Open_Date = open_date,
    Date_Last_Confirmed = date_last_confirmed,
    Updated_At = updated_at
  ) |>
  arrange(State, City, Station_Name, Station_ID)

write_csv(afdc_charging_station_clean, station_clean_output_path)

afdc_charging_state_clean <- afdc_charging_station_clean |>
  group_by(State, State_Abbr) |>
  summarise(
    AFDC_Charging_Station_Count = n(),
    Level2_Charger_Count = sum(Level2_Charger_Count, na.rm = TRUE),
    DC_Fast_Charger_Count = sum(DC_Fast_Charger_Count, na.rm = TRUE),
    Public_Station_Count = sum(Access_Type == "Public", na.rm = TRUE),
    Private_Station_Count = sum(Access_Type == "Private", na.rm = TRUE),
    .groups = "drop"
  ) |>
  right_join(state_lookup, by = c("State", "State_Abbr")) |>
  mutate(
    across(
      c(
        AFDC_Charging_Station_Count,
        Level2_Charger_Count,
        DC_Fast_Charger_Count,
        Public_Station_Count,
        Private_Station_Count
      ),
      ~ replace_na(.x, 0)
    )
  ) |>
  arrange(State)

write_csv(afdc_charging_state_clean, state_clean_output_path)

message("AFDC station pipeline complete.")
message("State file: ", state_clean_output_path)
message("Station-level file: ", station_clean_output_path)
