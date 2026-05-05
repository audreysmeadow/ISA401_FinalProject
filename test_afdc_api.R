source("R/00_setup.R")

# Use the updated NLR endpoint
afdc_url <- "https://developer.nlr.gov/api/alt-fuel-stations/v1.json"

test_request <- request(afdc_url) |>
  req_url_query(
    api_key = AFDC_API_KEY,
    fuel_type = "ELEC",
    country = "US",
    status = "E",
    access = "public",
    limit = 10
  )

test_response <- req_perform(test_request)

test_json <- resp_body_json(test_response, simplifyVector = TRUE)

test_stations <- as_tibble(test_json$fuel_stations)

print(test_stations)
glimpse(test_stations)
