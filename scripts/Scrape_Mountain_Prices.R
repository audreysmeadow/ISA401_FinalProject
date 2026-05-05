source("scripts/setup.R")

url <- "https://mountain.com/blog/best-streaming-services/"

page <- read_html(url)

# This may need adjustment depending on page structure
tables <- page %>%
  html_elements("table") %>%
  html_table(fill = TRUE)

# Save raw scraped table if available
if (length(tables) > 0) {
  raw_prices <- tables[[1]] %>%
    clean_names()
} else {
  raw_prices <- tibble()
}

write_csv(raw_prices, "data/raw/mountain_prices_raw.csv")

# Backup clean manual table if scraping is messy
platform_prices <- tibble(
  platform = c(
    "Netflix",
    "Disney+",
    "Max",
    "Hulu",
    "Prime Video",
    "Peacock",
    "Paramount+",
    "Apple TV+"
  ),
  monthly_price = c(NA, NA, NA, NA, NA, NA, NA, NA),
  plan_type = "standard",
  source = "Mountain"
)

write_csv(platform_prices, "data/raw/platform_prices_manual_template.csv")
