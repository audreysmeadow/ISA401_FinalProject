# 00_setup.R
# Load packages, config, folders, and shared helpers.

required_packages <- c(
  "tidyverse",
  "tidycensus",
  "readxl",
  "janitor",
  "httr2",
  "rvest",
  "robotstxt",
  "RANN",
  "knitr"
)

project_library <- file.path(getwd(), "r_libs")
dir.create(project_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(project_library, .libPaths()))

installed_packages <- rownames(installed.packages())

for (pkg in required_packages) {
  if (!(pkg %in% installed_packages)) {
    install.packages(pkg, lib = project_library, repos = "https://cloud.r-project.org")
  }
}

library(tidyverse)
library(tidycensus)
library(readxl)
library(janitor)
library(httr2)
library(rvest)
library(robotstxt)
library(RANN)
library(knitr)

config_path <- "config/config.R"

if (file.exists(config_path)) {
  source(config_path)
}

AFDC_API_KEY <- if (exists("AFDC_API_KEY")) {
  AFDC_API_KEY
} else if (nzchar(Sys.getenv("AFDC_API_KEY"))) {
  Sys.getenv("AFDC_API_KEY")
} else if (nzchar(Sys.getenv("NREL_API_KEY"))) {
  Sys.getenv("NREL_API_KEY")
} else {
  "DEMO_KEY"
}

AFDC_BASE_URL <- if (exists("AFDC_BASE_URL")) {
  AFDC_BASE_URL
} else {
  "https://developer.nrel.gov/api/alt-fuel-stations/v1.json"
}

if (exists("CENSUS_API_KEY")) {
  census_api_key(CENSUS_API_KEY, install = FALSE, overwrite = TRUE)
} else if (nzchar(Sys.getenv("CENSUS_API_KEY"))) {
  census_api_key(Sys.getenv("CENSUS_API_KEY"), install = FALSE, overwrite = TRUE)
}

raw_dir <- "data/raw"
clean_dir <- "data/clean"
final_dir <- "data/final"
dashboard_dir <- "dashboard"
validation_dir <- "validation"
docs_dir <- "docs"

state_lookup <- tibble(
  State = state.name,
  State_Abbr = state.abb
)

clean_numeric <- function(x) {
  as.numeric(str_remove_all(as.character(x), "[,$%]"))
}

safe_divide <- function(numerator, denominator, multiplier = 1) {
  if_else(
    is.na(numerator) | is.na(denominator) | denominator <= 0,
    NA_real_,
    multiplier * numerator / denominator
  )
}

haversine_miles <- function(lat1, lon1, lat2, lon2) {
  earth_radius_miles <- 3958.7613
  to_rad <- pi / 180

  phi1 <- lat1 * to_rad
  phi2 <- lat2 * to_rad
  delta_phi <- (lat2 - lat1) * to_rad
  delta_lambda <- (lon2 - lon1) * to_rad

  a <- sin(delta_phi / 2)^2 +
    cos(phi1) * cos(phi2) * sin(delta_lambda / 2)^2

  2 * earth_radius_miles * atan2(sqrt(a), sqrt(1 - a))
}

lonlat_to_unit_sphere <- function(latitude, longitude) {
  lat_rad <- latitude * pi / 180
  lon_rad <- longitude * pi / 180

  cbind(
    x = cos(lat_rad) * cos(lon_rad),
    y = cos(lat_rad) * sin(lon_rad),
    z = sin(lat_rad)
  )
}
