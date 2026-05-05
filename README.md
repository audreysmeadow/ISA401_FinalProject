# EV Expansion Opportunity Across U.S. States

## Business Question

Which U.S. states offer the strongest opportunity for electric vehicle expansion based on EV adoption, charging infrastructure, consumer-facing charger availability, and economic readiness?

## Data Sources

1. AFDC Electric Vehicle Registrations by State
2. AFDC Alternative Fuel Stations API
3. Census ACS Data via tidycensus
4. PlugShare U.S. Directory

## Workflow

Set up -> Gather/Clean each source -> Merge -> Calculate scores -> Validate -> Export dashboard data

Run the full workflow from the project root with:

```sh
Rscript R/09_run_all_pipelines.R
```

Primary outputs:

- `data/final/us_ev_state_final.csv`
- `data/final/us_ev_state_data_dictionary.csv`
- `data/final/afdc_charging_station_data_dictionary.csv`
- `validation/validation_summary.csv`
- `validation/validation_results.csv`
- `dashboard/us_ev_state_dashboard.csv`
- `dashboard/afdc_charging_station_locations.csv`
- `exploratory/exploratory_summary.md`
- `exploratory/charts/*.png`
