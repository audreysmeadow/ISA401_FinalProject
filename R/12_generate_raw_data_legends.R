# 12_generate_raw_data_legends.R
# Generate a field legend for each raw data file.

source("R/00_setup.R")

legend_csv_path <- file.path(docs_dir, "raw_data_field_legend.csv")
legend_md_path <- file.path(docs_dir, "raw_data_field_legend.md")

dir.create(docs_dir, recursive = TRUE, showWarnings = FALSE)

field_descriptions <- tribble(
  ~Raw_File, ~Field, ~Description, ~Source,
  "ev_registration_state_raw.csv", "State", "U.S. state name.", "AFDC EV registration Excel download",
  "ev_registration_state_raw.csv", "Registration Count", "Registered light-duty electric vehicles by state.", "AFDC EV registration Excel download",
  "ev_registration_state_raw.csv", "...3", "Blank/source artifact column from the downloaded spreadsheet.", "AFDC EV registration Excel download",
  "ev_registration_state_raw.csv", "...4", "Blank/source artifact column from the downloaded spreadsheet.", "AFDC EV registration Excel download",
  "afdc_charging_raw.csv", "id", "Unique AFDC station identifier.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "station_name", "Charging station name.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "street_address", "Station street address.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "city", "Station city.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "state", "Two-letter state abbreviation.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "zip", "Station ZIP code.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "country", "Country code.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "status_code", "AFDC station status code.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "access_code", "Station access type, such as public or private.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "fuel_type_code", "Fuel type code. Filtered to ELEC.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "ev_level2_evse_num", "Number of Level 2 EVSE at the station.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "ev_dc_fast_num", "Number of DC fast chargers at the station.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "ev_network", "Charging network name.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "latitude", "Station latitude.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "longitude", "Station longitude.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "date_last_confirmed", "Date the station record was last confirmed.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "open_date", "Station opening date when available.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "updated_at", "Timestamp when the station record was updated.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "owner_type_code", "AFDC owner type code.", "AFDC Alternative Fuel Stations API",
  "afdc_charging_raw.csv", "facility_type", "AFDC facility type code.", "AFDC Alternative Fuel Stations API",
  "aaa_state_gas_prices_raw.csv", "Source_URL", "Original AAA state gas price averages page.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Retrieval_URL", "Text-reader URL used to retrieve the page content when direct access is blocked.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Scrape_Date", "Date the AAA page was scraped.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Price_Date", "AAA-reported price date from the page text.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Raw_Table_Row", "Raw markdown table row from the AAA state gas price table.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "State", "State or district name in the AAA table.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "State_Abbr", "Two-letter state abbreviation from the AAA state link.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Regular_Raw", "Raw regular gas price string.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Mid_Grade_Raw", "Raw mid-grade gas price string.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Premium_Raw", "Raw premium gas price string.", "AAA State Gas Price Averages",
  "aaa_state_gas_prices_raw.csv", "Diesel_Raw", "Raw diesel price string.", "AAA State Gas Price Averages"
)

raw_files <- list.files(raw_dir, pattern = "\\.csv$", full.names = TRUE)

legend <- map_dfr(raw_files, function(path) {
  raw_file <- basename(path)

  if (file.info(path)$size == 0) {
    return(tibble(
      Raw_File = raw_file,
      Field = NA_character_,
      Data_Type = NA_character_,
      Description = "Raw file is empty.",
      Source = NA_character_
    ))
  }

  sample_data <- suppressMessages(read_csv(path, n_max = 100, show_col_types = FALSE))
  fields <- names(sample_data)
  types <- map_chr(sample_data, ~ paste(class(.x), collapse = "/"))

  tibble(
    Raw_File = raw_file,
    Field = fields,
    Data_Type = types
  ) |>
    left_join(field_descriptions, by = c("Raw_File", "Field")) |>
    mutate(
      Description = replace_na(Description, "Field from raw source. Confirm exact meaning from source documentation if used in analysis."),
      Source = if_else(
        is.na(Source),
        case_when(
          str_detect(Raw_File, "census") ~ "Census ACS via tidycensus",
          str_detect(Raw_File, "aaa") ~ "AAA State Gas Price Averages",
          TRUE ~ "Raw source"
        ),
        Source
      )
    )
})

census_labels <- tibble(
  Raw_File = "census_state_raw.csv",
  Field = c(
    "GEOID", "NAME",
    "total_populationE", "total_populationM",
    "median_household_incomeE", "median_household_incomeM",
    "per_capita_incomeE", "per_capita_incomeM",
    "poverty_universeE", "poverty_universeM",
    "poverty_countE", "poverty_countM",
    "aggregate_travel_time_minutesE", "aggregate_travel_time_minutesM",
    "workers_with_commuteE", "workers_with_commuteM"
  ),
  Description = c(
    "Census state geographic identifier.",
    "State name.",
    "ACS estimate for total population.",
    "Margin of error for total population.",
    "ACS estimate for median household income.",
    "Margin of error for median household income.",
    "ACS estimate for per capita income.",
    "Margin of error for per capita income.",
    "ACS estimate for poverty universe.",
    "Margin of error for poverty universe.",
    "ACS estimate for people below poverty level.",
    "Margin of error for people below poverty level.",
    "ACS estimate for aggregate travel time to work in minutes.",
    "Margin of error for aggregate travel time to work.",
    "ACS estimate for workers with reported commute time.",
    "Margin of error for workers with reported commute time."
  ),
  Source = "Census ACS via tidycensus"
)

legend <- legend |>
  left_join(
    census_labels,
    by = c("Raw_File", "Field"),
    suffix = c("", "_Census")
  ) |>
  mutate(
    Description = coalesce(Description_Census, Description),
    Source = coalesce(Source_Census, Source)
  ) |>
  select(Raw_File, Field, Data_Type, Description, Source) |>
  arrange(Raw_File, Field)

write_csv(legend, legend_csv_path)

md_lines <- c(
  "# Raw Data Field Legend",
  "",
  "This legend describes fields found in the raw data files generated by the R acquisition scripts.",
  ""
)

for (raw_file in unique(legend$Raw_File)) {
  table_data <- legend |>
    filter(Raw_File == raw_file) |>
    select(Field, Data_Type, Description, Source)

  md_lines <- c(
    md_lines,
    paste0("## ", raw_file),
    "",
    knitr::kable(table_data, format = "pipe"),
    ""
  )
}

write_lines(md_lines, legend_md_path)

message("Raw data field legends complete.")
message("CSV legend: ", legend_csv_path)
message("Markdown legend: ", legend_md_path)
