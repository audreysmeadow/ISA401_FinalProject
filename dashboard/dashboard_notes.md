# Dashboard Notes

Use `dashboard/us_ev_state_dashboard.csv` for state-level visuals.

Use `dashboard/afdc_charging_station_locations.csv` for station-level map visuals. In Tableau, set `Latitude` and `Longitude` as geographic fields, then plot stations as point marks on a U.S. map.

Recommended visuals:
- U.S. state map colored by EV_Opportunity_Score.
- Charging station point map using Latitude and Longitude from `afdc_charging_station_locations.csv`.
- Top 10 states bar chart filtered by Top_10_Flag.
- Scatterplot comparing EVs_Per_10000_Residents and Chargers_Per_1000_EVs.
- AFDC vs PlugShare comparison using AFDC_Charging_Station_Count and PlugShare_Station_Count.
- Economic readiness view using Median_Household_Income, Poverty_Rate, Population, and Economic_Readiness_Score.
- Category summary grouped by Opportunity_Category.

The final score uses the project summary weights: 35% EV adoption, 25% official charging infrastructure, 15% consumer-facing charger visibility, and 25% economic readiness.
