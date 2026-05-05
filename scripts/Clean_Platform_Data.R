source("scripts/setup.R")

platform_prices <- read_csv("data/raw/platform_prices_manual_template.csv")

platform_clean <- platform_prices %>%
  mutate(
    platform = case_when(
      str_detect(str_to_lower(platform), "netflix") ~ "Netflix",
      str_detect(str_to_lower(platform), "disney") ~ "Disney+",
      str_detect(str_to_lower(platform), "max|hbo") ~ "Max",
      str_detect(str_to_lower(platform), "hulu") ~ "Hulu",
      str_detect(str_to_lower(platform), "prime|amazon") ~ "Prime Video",
      str_detect(str_to_lower(platform), "peacock") ~ "Peacock",
      str_detect(str_to_lower(platform), "paramount") ~ "Paramount+",
      str_detect(str_to_lower(platform), "apple") ~ "Apple TV+",
      TRUE ~ platform
    ),
    monthly_price = parse_number(as.character(monthly_price))
  ) %>%
  distinct(platform, .keep_all = TRUE)

write_csv(platform_clean, "data/processed/platform_data_clean.csv")
