# 04_plugshare_scraping_pipeline.R
# Scrape and clean PlugShare U.S. charging directory data.

source("R/00_setup.R")

raw_output_path <- file.path(raw_dir, "plugshare_state_raw.csv")
clean_output_path <- file.path(clean_dir, "plugshare_state_clean.csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Check robots.txt
# ------------------------------------------------------------

robotstxt::paths_allowed(
  paths = "https://www.plugshare.com/directory/us"
)

# ------------------------------------------------------------
# Scraping function
# ------------------------------------------------------------

scrape_plugshare_states <- function() {

  plugshare_url <- "https://www.plugshare.com/directory/us"

  plugshare_webpage <- rvest::read_html(plugshare_url)

  page_text <- plugshare_webpage |>
    html_text2()

  # Save raw scraped text for reproducibility
  write_lines(page_text, raw_output_path)

  # Create a regex pattern using all 50 state names
  state_pattern <- paste(state.name, collapse = "|")

  matches <- str_match_all(
    page_text,
    paste0("(", state_pattern, ")\\s+([0-9,]+)\\s+Stations")
  )[[1]]

  if (nrow(matches) == 0) {
    stop("No PlugShare state station counts were found on the directory page.")
  }

  plugshare_df <- tibble(
    State = matches[, 2],
    PlugShare_Station_Count = clean_numeric(matches[, 3]),
    Source = "PlugShare U.S. Directory",
    Scrape_Date = Sys.Date()
  ) |>
    left_join(state_lookup, by = "State") |>
    select(
      State,
      State_Abbr,
      PlugShare_Station_Count,
      Source,
      Scrape_Date
    ) |>
    arrange(State)

  return(plugshare_df)
}

# ------------------------------------------------------------
# Run scrape
# ------------------------------------------------------------

plugshare_state_clean <- scrape_plugshare_states()

# Save clean output
write_csv(
  plugshare_state_clean,
  clean_output_path
)

if (nrow(plugshare_state_clean) != 50) {
  warning("Expected 50 states, but found ", nrow(plugshare_state_clean), " rows.")
}

message("PlugShare scraping pipeline complete.")
message("Raw file saved to: ", raw_output_path)
message("Clean file saved to: ", clean_output_path)
