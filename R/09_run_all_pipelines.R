# 09_run_all_pipelines.R
# Runs the full EV opportunity data workflow in order.

pipeline_scripts <- c(
  "R/01_ev_registration_state_pipeline.R",
  "R/02_afdc_charging_pipeline.R",
  "R/03_census_state_pipeline.R",
  "R/04_plugshare_scraping_pipeline.R",
  "R/05_merge_state_dataset.R",
  "R/06_calculate_scores.R",
  "R/07_validate_dataset.R",
  "R/08_export_dashboard_data.R",
  "R/10_exploratory_summaries.R"
)

for (script in pipeline_scripts) {
  message("Running ", script, "...")
  source(script)
}

message("Full EV opportunity data workflow complete.")
