# 08_export_dashboard_data.R
# Export final dashboard-ready files and data dictionary.

source("R/00_setup.R")

# -----------------------------
# Input and output paths
# -----------------------------

final_input_path <- file.path(final_dir, "us_ev_state_final.csv")
station_input_path <- file.path(clean_dir, "afdc_charging_station_clean.csv")
dashboard_output_path <- file.path(dashboard_dir, "us_ev_state_dashboard.csv")
station_dashboard_output_path <- file.path(dashboard_dir, "afdc_charging_station_locations.csv")
data_dictionary_output_path <- file.path(final_dir, "us_ev_state_data_dictionary.csv")
station_data_dictionary_output_path <- file.path(final_dir, "afdc_charging_station_data_dictionary.csv")
dashboard_notes_path <- file.path(dashboard_dir, "dashboard_notes.md")

dir.create(dashboard_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(final_input_path) || file.info(final_input_path)$size == 0) {
  stop("Missing final scored dataset. Run R/06_calculate_scores.R first.")
}

final_state <- read_csv(final_input_path, show_col_types = FALSE)

station_data <- if (file.exists(station_input_path) && file.info(station_input_path)$size > 0) {
  read_csv(station_input_path, show_col_types = FALSE)
} else {
  warning(
    "Missing station-level AFDC file at ",
    station_input_path,
    ". Run R/02_afdc_charging_pipeline.R to export station map data."
  )
  tibble()
}

# -----------------------------
# Dashboard-ready export
# -----------------------------

dashboard_data <- final_state |>
  transmute(
    State,
    State_Abbr,
    EV_Count,
    Population,
    Median_Household_Income,
    Poverty_Rate,
    Average_Commute_Time,
    AFDC_Charging_Station_Count,
    Official_Charger_Count,
    Level2_Charger_Count,
    DC_Fast_Charger_Count,
    Public_Station_Count,
    Private_Station_Count,
    PlugShare_Station_Count,
    EVs_Per_10000_Residents,
    Chargers_Per_1000_EVs,
    PlugShare_Per_10000_Residents,
    AFDC_vs_PlugShare_Gap,
    EV_Adoption_Score,
    Official_Charging_Infrastructure_Score,
    Consumer_Facing_Charging_Visibility_Score,
    Economic_Readiness_Score,
    EV_Opportunity_Score,
    Opportunity_Rank,
    Opportunity_Category,
    Top_10_Flag = Opportunity_Rank <= 10,
    Dashboard_Refresh_Date = Sys.Date()
  ) |>
  arrange(Opportunity_Rank)

write_csv(dashboard_data, dashboard_output_path)

station_dashboard_data <- station_data |>
  left_join(
    final_state |>
      select(
        State,
        State_Abbr,
        EV_Opportunity_Score,
        Opportunity_Rank,
        Opportunity_Category,
        EVs_Per_10000_Residents,
        Chargers_Per_1000_EVs
      ),
    by = c("State", "State_Abbr")
  ) |>
  mutate(
    Has_DC_Fast_Charger = DC_Fast_Charger_Count > 0,
    Has_Level2_Charger = Level2_Charger_Count > 0,
    Dashboard_Refresh_Date = Sys.Date()
  ) |>
  select(
    Station_ID,
    Station_Name,
    Street_Address,
    City,
    State,
    State_Abbr,
    ZIP,
    Latitude,
    Longitude,
    Access_Type,
    Station_Status,
    EV_Network,
    Level2_Charger_Count,
    DC_Fast_Charger_Count,
    Total_EVSE_Count,
    Has_Level2_Charger,
    Has_DC_Fast_Charger,
    Owner_Type_Code,
    Facility_Type,
    Open_Date,
    Date_Last_Confirmed,
    Updated_At,
    EV_Opportunity_Score,
    Opportunity_Rank,
    Opportunity_Category,
    EVs_Per_10000_Residents,
    Chargers_Per_1000_EVs,
    Dashboard_Refresh_Date
  ) |>
  arrange(State, City, Station_Name, Station_ID)

write_csv(station_dashboard_data, station_dashboard_output_path)

# -----------------------------
# Data dictionary
# -----------------------------

data_dictionary <- tribble(
  ~Field, ~Description, ~Source, ~Calculation,
  "State", "U.S. state name.", "State lookup", "Direct lookup value.",
  "State_Abbr", "Two-letter state abbreviation.", "State lookup", "Direct lookup value.",
  "EV_Count", "Registered light-duty electric vehicles by state.", "AFDC EV registrations", "Renamed from ev_registration_count.",
  "Population", "Total state population.", "Census ACS 5-year", "ACS B01003_001 estimate.",
  "Median_Household_Income", "Median household income in dollars.", "Census ACS 5-year", "ACS B19013_001 estimate.",
  "Per_Capita_Income", "Per capita income in dollars.", "Census ACS 5-year", "ACS B19301_001 estimate.",
  "Pct_Bachelors_or_Higher", "Percent of adults age 25+ with a bachelor's degree or higher.", "Census ACS 5-year", "Bachelor's or higher count divided by education 25+ universe.",
  "Unemployment_Rate", "State unemployment rate.", "Census ACS 5-year", "Unemployed population divided by civilian labor force.",
  "Poverty_Rate", "Percent of people below poverty level.", "Census ACS 5-year", "Poverty count divided by poverty universe.",
  "Average_Commute_Time", "Average commute time in minutes.", "Census ACS 5-year", "Aggregate travel time divided by workers with commute time.",
  "AFDC_Charging_Station_Count", "Official AFDC electric charging station count.", "AFDC Alternative Fuel Stations API", "Count of electric station records by state.",
  "Official_Charger_Count", "Total official Level 2 and DC fast charger count.", "AFDC Alternative Fuel Stations API", "Level2_Charger_Count plus DC_Fast_Charger_Count.",
  "Level2_Charger_Count", "Official Level 2 EVSE count.", "AFDC Alternative Fuel Stations API", "Sum of ev_level2_evse_num by state.",
  "DC_Fast_Charger_Count", "Official DC fast charger count.", "AFDC Alternative Fuel Stations API", "Sum of ev_dc_fast_num by state.",
  "Public_Station_Count", "Official public electric station count.", "AFDC Alternative Fuel Stations API", "Count of AFDC records where access_code is public.",
  "Private_Station_Count", "Official private electric station count.", "AFDC Alternative Fuel Stations API", "Count of AFDC records where access_code is private.",
  "PlugShare_Station_Count", "Consumer-facing station count scraped from PlugShare.", "PlugShare U.S. Directory", "Parsed state station count from directory text.",
  "EVs_Per_10000_Residents", "Population-normalized EV adoption rate.", "Calculated", "EV_Count divided by Population times 10,000.",
  "Chargers_Per_1000_EVs", "Official charger availability relative to registered EVs.", "Calculated", "Official_Charger_Count divided by EV_Count times 1,000.",
  "PlugShare_Per_10000_Residents", "Consumer-facing charger visibility relative to population.", "Calculated", "PlugShare_Station_Count divided by Population times 10,000.",
  "AFDC_vs_PlugShare_Gap", "Difference between official AFDC stations and PlugShare stations.", "Calculated", "AFDC_Charging_Station_Count minus PlugShare_Station_Count.",
  "EV_Adoption_Score", "0-100 normalized EV adoption component.", "Calculated", "Scaled EVs_Per_10000_Residents.",
  "Official_Charging_Infrastructure_Score", "0-100 normalized official infrastructure component.", "Calculated", "Scaled Chargers_Per_1000_EVs.",
  "Consumer_Facing_Charging_Visibility_Score", "0-100 normalized consumer-facing visibility component.", "Calculated", "Scaled PlugShare_Per_10000_Residents.",
  "Median_Income_Score", "0-100 normalized median income component.", "Calculated", "Scaled Median_Household_Income.",
  "Population_Score", "0-100 normalized population component.", "Calculated", "Scaled Population.",
  "Poverty_Rate_Score", "0-100 normalized inverse poverty component.", "Calculated", "100 minus scaled Poverty_Rate.",
  "Economic_Readiness_Score", "0-100 economic readiness component.", "Calculated", "40% income score, 30% population score, 30% inverse poverty score.",
  "EV_Opportunity_Score", "Final EV expansion opportunity score.", "Calculated", "35% adoption, 25% official infrastructure, 15% PlugShare visibility, 25% economic readiness.",
  "Opportunity_Rank", "Rank order by EV_Opportunity_Score.", "Calculated", "1 is highest opportunity.",
  "Opportunity_Category", "High, Medium, or Low opportunity group.", "Calculated", "States split into score-based thirds.",
  "Top_10_Flag", "Identifies top 10 opportunity states for dashboard filtering.", "Calculated", "Opportunity_Rank less than or equal to 10.",
  "Dashboard_Refresh_Date", "Date the dashboard extract was created.", "Calculated", "System date when export script ran."
)

write_csv(data_dictionary, data_dictionary_output_path)

station_data_dictionary <- tribble(
  ~Field, ~Description, ~Source, ~Use_In_Dashboard,
  "Station_ID", "Unique AFDC station identifier.", "AFDC Alternative Fuel Stations API", "Detail field / unique key.",
  "Station_Name", "Charging station name.", "AFDC Alternative Fuel Stations API", "Tooltip / station label.",
  "Street_Address", "Station street address.", "AFDC Alternative Fuel Stations API", "Tooltip.",
  "City", "Station city.", "AFDC Alternative Fuel Stations API", "Tooltip and filter.",
  "State", "Station state name.", "AFDC Alternative Fuel Stations API plus state lookup", "Filter and map grouping.",
  "State_Abbr", "Two-letter state abbreviation.", "AFDC Alternative Fuel Stations API", "Filter and relationship key.",
  "ZIP", "Station ZIP code.", "AFDC Alternative Fuel Stations API", "Tooltip and local filtering.",
  "Latitude", "Station latitude.", "AFDC Alternative Fuel Stations API", "Map latitude coordinate.",
  "Longitude", "Station longitude.", "AFDC Alternative Fuel Stations API", "Map longitude coordinate.",
  "Access_Type", "Public or private station access.", "AFDC Alternative Fuel Stations API", "Color, filter, or tooltip.",
  "Station_Status", "Station availability status.", "AFDC Alternative Fuel Stations API", "Filter or tooltip.",
  "EV_Network", "Charging network name when available.", "AFDC Alternative Fuel Stations API", "Filter, color, or tooltip.",
  "Level2_Charger_Count", "Number of Level 2 EVSE at the station.", "AFDC Alternative Fuel Stations API", "Tooltip or station size.",
  "DC_Fast_Charger_Count", "Number of DC fast chargers at the station.", "AFDC Alternative Fuel Stations API", "Tooltip, filter, or station size.",
  "Total_EVSE_Count", "Total Level 2 plus DC fast chargers at the station.", "Calculated from AFDC fields", "Station mark size.",
  "Has_Level2_Charger", "TRUE if the station has at least one Level 2 charger.", "Calculated", "Filter.",
  "Has_DC_Fast_Charger", "TRUE if the station has at least one DC fast charger.", "Calculated", "Filter.",
  "Owner_Type_Code", "AFDC owner type code.", "AFDC Alternative Fuel Stations API", "Tooltip / optional filter.",
  "Facility_Type", "AFDC facility type code.", "AFDC Alternative Fuel Stations API", "Tooltip / optional filter.",
  "Open_Date", "Station open date when available.", "AFDC Alternative Fuel Stations API", "Tooltip.",
  "Date_Last_Confirmed", "Date AFDC last confirmed the station record.", "AFDC Alternative Fuel Stations API", "Data freshness tooltip.",
  "Updated_At", "Timestamp when AFDC station record was updated.", "AFDC Alternative Fuel Stations API", "Data freshness tooltip.",
  "EV_Opportunity_Score", "State-level EV opportunity score joined onto each station.", "Final state dataset", "Color, tooltip, or dashboard context.",
  "Opportunity_Rank", "State-level opportunity rank joined onto each station.", "Final state dataset", "Tooltip or filter.",
  "Opportunity_Category", "High, Medium, or Low opportunity category joined onto each station.", "Final state dataset", "Color or filter.",
  "EVs_Per_10000_Residents", "State-level EV adoption rate joined onto each station.", "Final state dataset", "Tooltip or context.",
  "Chargers_Per_1000_EVs", "State-level charger availability rate joined onto each station.", "Final state dataset", "Tooltip or context.",
  "Dashboard_Refresh_Date", "Date the station map extract was created.", "Calculated", "Data freshness tooltip."
)

write_csv(station_data_dictionary, station_data_dictionary_output_path)

# -----------------------------
# Dashboard notes
# -----------------------------

dashboard_notes <- c(
  "# Dashboard Notes",
  "",
  "Use `dashboard/us_ev_state_dashboard.csv` for state-level visuals.",
  "",
  "Use `dashboard/afdc_charging_station_locations.csv` for station-level map visuals. In Tableau, set `Latitude` and `Longitude` as geographic fields, then plot stations as point marks on a U.S. map.",
  "",
  "Recommended visuals:",
  "- U.S. state map colored by EV_Opportunity_Score.",
  "- Charging station point map using Latitude and Longitude from `afdc_charging_station_locations.csv`.",
  "- Top 10 states bar chart filtered by Top_10_Flag.",
  "- Scatterplot comparing EVs_Per_10000_Residents and Chargers_Per_1000_EVs.",
  "- AFDC vs PlugShare comparison using AFDC_Charging_Station_Count and PlugShare_Station_Count.",
  "- Economic readiness view using Median_Household_Income, Poverty_Rate, Population, and Economic_Readiness_Score.",
  "- Category summary grouped by Opportunity_Category.",
  "",
  "The final score uses the project summary weights: 35% EV adoption, 25% official charging infrastructure, 15% consumer-facing charger visibility, and 25% economic readiness."
)

write_lines(dashboard_notes, dashboard_notes_path)

message("Dashboard export complete.")
message("Dashboard data saved to: ", dashboard_output_path)
message("Station map data saved to: ", station_dashboard_output_path)
message("Data dictionary saved to: ", data_dictionary_output_path)
message("Station data dictionary saved to: ", station_data_dictionary_output_path)
message("Dashboard notes saved to: ", dashboard_notes_path)
