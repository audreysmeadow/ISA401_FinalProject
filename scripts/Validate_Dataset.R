source("scripts/setup.R")

data <- read_csv("data/processed/final_streaming_dataset.csv")

missing_report <- data %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(
    cols = everything(),
    names_to = "column",
    values_to = "missing_count"
  ) %>%
  arrange(desc(missing_count))

duplicates <- data %>%
  count(title_clean, platform) %>%
  filter(n > 1)

platform_missing_prices <- data %>%
  filter(is.na(monthly_price)) %>%
  distinct(platform)

write_csv(missing_report, "data/validation/missing_values_report.csv")
write_csv(duplicates, "data/validation/duplicate_title_platform_pairs.csv")
write_csv(platform_missing_prices, "data/validation/platforms_missing_prices.csv")
