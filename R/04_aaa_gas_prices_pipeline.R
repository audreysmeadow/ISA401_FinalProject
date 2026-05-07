# 04_aaa_gas_prices_pipeline.R
# Scrape AAA state gas price averages.

source("R/00_setup.R")

source_url <- "https://gasprices.aaa.com/state-gas-price-averages/"
reader_url <- paste0("https://r.jina.ai/http://r.jina.ai/http://", source_url)

raw_output_path <- file.path(raw_dir, "aaa_state_gas_prices_raw.csv")
clean_output_path <- file.path(clean_dir, "aaa_state_gas_prices_clean.csv")

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------
# Robots.txt check
# -----------------------------

if (!robotstxt::paths_allowed(paths = source_url)) {
  stop("AAA robots.txt does not allow scraping: ", source_url)
}

# -----------------------------
# Read source page as text
# -----------------------------

page_lines <- readLines(reader_url, warn = FALSE, encoding = "UTF-8")
page_text <- paste(page_lines, collapse = "\n")

if (str_detect(str_to_lower(page_text), "cloudflare|sorry, you have been blocked")) {
  stop("AAA returned a blocked page instead of the state gas price table.")
}

price_date <- str_match(page_text, "Price as of\\s+([0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4})")[, 2]

# -----------------------------
# Parse markdown table rows
# -----------------------------

table_lines <- page_lines[
  str_detect(
    page_lines,
    "^\\| \\[[^\\]]+\\]\\(https://gasprices\\.aaa\\.com/\\?state=[A-Z]{2}\\) \\| \\$"
  )
]

if (length(table_lines) == 0) {
  stop("No AAA state gas price table rows were found.")
}

row_matches <- str_match(
  table_lines,
  "^\\| \\[([^\\]]+)\\]\\(https://gasprices\\.aaa\\.com/\\?state=([A-Z]{2})\\) \\| (\\$[0-9.]+) \\| (\\$[0-9.]+) \\| (\\$[0-9.]+) \\| (\\$[0-9.]+) \\|"
)

aaa_raw <- tibble(
  Source_URL = source_url,
  Retrieval_URL = reader_url,
  Scrape_Date = Sys.Date(),
  Price_Date = price_date,
  Raw_Table_Row = table_lines,
  State = row_matches[, 2],
  State_Abbr = row_matches[, 3],
  Regular_Raw = row_matches[, 4],
  Mid_Grade_Raw = row_matches[, 5],
  Premium_Raw = row_matches[, 6],
  Diesel_Raw = row_matches[, 7]
) |>
  filter(!is.na(State), !is.na(State_Abbr))

write_csv(aaa_raw, raw_output_path)

# -----------------------------
# Clean state-level gas price data
# -----------------------------

aaa_clean <- aaa_raw |>
  filter(State %in% state.name) |>
  transmute(
    State,
    State_Abbr,
    Regular_Gas_Price = clean_numeric(Regular_Raw),
    Mid_Grade_Gas_Price = clean_numeric(Mid_Grade_Raw),
    Premium_Gas_Price = clean_numeric(Premium_Raw),
    Diesel_Gas_Price = clean_numeric(Diesel_Raw),
    Gas_Price_Date = Price_Date,
    Source = "AAA State Gas Price Averages",
    Source_URL,
    Scrape_Date
  ) |>
  arrange(State)

if (nrow(aaa_clean) != 50) {
  warning("Expected 50 states after excluding non-state rows, but found ", nrow(aaa_clean), ".")
}

write_csv(aaa_clean, clean_output_path)

message("AAA gas price scrape complete.")
message("Raw file saved to: ", raw_output_path)
message("Clean file saved to: ", clean_output_path)
