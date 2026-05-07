# EV Expansion Opportunity Across U.S. States

## Data Sources Used

1. AFDC EV registrations by state
2. AFDC Alternative Fuel Stations API
3. Census ACS data via tidycensus
4. AAA state gas price averages scrape

PlugShare and AutoEvolution were removed. The scraped source is now AAA state gas prices.

## Run Workflow

```sh
Rscript R/09_run_all_pipelines.R
```

## New Outputs

- `data/final/afdc_charging_station_distance_summary.csv`
- `data/final/ev_state_analysis_final.csv`
- `data/clean/aaa_state_gas_prices_clean.csv`
- `dashboard/afdc_charging_station_distance_summary.csv`
- `dashboard/ev_state_analysis_final.csv`
- `docs/raw_data_field_legend.csv`
- `docs/raw_data_field_legend.md`
- `docs/tidy_data_notes.md`
- `validation/tidy_data_validation.csv`
