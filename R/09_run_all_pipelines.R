# 09_run_all_pipelines.R
# Runs available project data acquisition and documentation outputs.

pipeline_scripts <- c(
  "R/01_ev_registration_state_pipeline.R",
  "R/02_afdc_charging_pipeline.R",
  "R/03_census_state_pipeline.R",
  "R/04_aaa_gas_prices_pipeline.R",
  "R/11_calculate_station_spacing.R",
  "R/08_build_final_state_dataset.R",
  "R/12_generate_raw_data_legends.R",
  "R/13_validate_tidy_data.R"
)

for (script in pipeline_scripts) {
  message("Running ", script, "...")
  source(script)
}

message("Project data acquisition, final dataset, validation, and documentation workflow complete.")
