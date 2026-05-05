# 00_setup.R
# Load packages, config, folders, and shared project settings.

# -----------------------------
# Packages
# -----------------------------

required_packages <- c(
  "tidyverse",
  "tidycensus",
  "readr",
  "janitor",
  "stringr",
  "httr2",
  "jsonlite",
  "rvest",
  "robotstxt",
  "scales",
  "knitr"
)

installed_packages <- rownames(installed.packages())

for (pkg in required_packages) {
  if (!(pkg %in% installed_packages)) {
    install.packages(pkg)
  }
}

library(tidyverse)
library(tidycensus)
library(readr)
library(janitor)
library(stringr)
library(httr2)
library(jsonlite)
library(rvest)
library(robotstxt)
library(scales)
library(knitr)

# -----------------------------
# Config
# -----------------------------

# -----------------------------
# Config
# -----------------------------

config_path <- "config/config.R"

if (file.exists(config_path)) {
  source(config_path)
} else {
  stop(
    "Missing config file at: ", config_path, "\n",
    "Current working directory is: ", getwd(), "\n",
    "Files here are: ", paste(list.files(), collapse = ", "), "\n",
    "Files one level up are: ", paste(list.files(".."), collapse = ", ")
  )
}

# Register Census API key for this R session
if (exists("CENSUS_API_KEY")) {
  census_api_key(CENSUS_API_KEY, install = FALSE, overwrite = TRUE)
}

# -----------------------------
# Project folders
# -----------------------------

raw_dir <- "data/raw"
clean_dir <- "data/clean"
final_dir <- "data/final"
validation_dir <- "validation"
dashboard_dir <- "dashboard"
exploratory_dir <- "exploratory"

# -----------------------------
# State lookup table
# -----------------------------

state_lookup <- tibble(
  State = state.name,
  State_Abbr = state.abb
)

# -----------------------------
# Helper functions
# -----------------------------

clean_numeric <- function(x) {
  as.numeric(str_remove_all(as.character(x), "[,$%]"))
}

scale_0_100 <- function(x) {
  if (all(is.na(x))) {
    return(rep(NA_real_, length(x)))
  }

  min_x <- min(x, na.rm = TRUE)
  max_x <- max(x, na.rm = TRUE)

  if (min_x == max_x) {
    return(if_else(is.na(x), NA_real_, 100))
  }

  100 * (x - min_x) / (max_x - min_x)
}

safe_divide <- function(numerator, denominator, multiplier = 1) {
  if_else(
    is.na(numerator) | is.na(denominator) | denominator <= 0,
    NA_real_,
    multiplier * numerator / denominator
  )
}
