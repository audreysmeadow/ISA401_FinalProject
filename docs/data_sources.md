# Data Sources

## 1. AFDC Electric Vehicle Registrations by State

- Method: structured Excel download
- Raw file: `data/raw/ev_registration_state_raw.csv`
- Clean file: `data/clean/ev_registration_state_clean.csv`
- Use: state EV counts

## 2. AFDC Alternative Fuel Stations API

- Method: API access
- Raw file: `data/raw/afdc_charging_raw.csv`
- Clean state file: `data/clean/afdc_charging_state_clean.csv`
- Clean station file: `data/clean/afdc_charging_station_clean.csv`
- Use: charging station counts, charger counts, station locations, and station spacing

## 3. Census ACS via tidycensus

- Method: API access through R
- Raw file: `data/raw/census_state_raw.csv`
- Clean file: `data/clean/census_state_clean.csv`
- Use: population, income, poverty, commute context, ACS estimate fields, and ACS margin-of-error fields

## 4. AAA State Gas Price Averages

- Method: web scraping
- Source page: https://gasprices.aaa.com/state-gas-price-averages/
- Raw file: `data/raw/aaa_state_gas_prices_raw.csv`
- Clean file: `data/clean/aaa_state_gas_prices_clean.csv`
- Use: regular, mid-grade, premium, and diesel gas prices by state

Note: Direct access to the AAA page may return Cloudflare, so the R scraper retrieves the page through a text-reader endpoint and parses the state price table from the page content. Robots.txt allows the source page.

## Final Tidy Outputs

- `data/final/ev_state_analysis_final.csv`: one row per state for Tableau or Power BI state comparisons.
- `data/clean/afdc_charging_station_clean.csv`: one row per charging station for map visuals.
- `validation/tidy_data_validation.csv`: confirms each analysis file has the expected row grain and no duplicate key rows.
