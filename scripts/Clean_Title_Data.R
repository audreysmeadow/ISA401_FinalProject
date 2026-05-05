source("scripts/setup.R")

availability <- read_csv("data/raw/movieofthenight_titles_raw.csv")
tmdb <- read_csv("data/raw/tmdb_titles_raw.csv")

availability_clean <- availability %>%
  clean_names() %>%
  mutate(
    title_clean = str_to_lower(str_squish(title)),
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
    )
  )

tmdb_clean <- tmdb %>%
  clean_names() %>%
  mutate(
    title_clean = str_to_lower(str_squish(title)),
    release_year = as.numeric(str_sub(release_date, 1, 4))
  )

title_data_clean <- availability_clean %>%
  left_join(tmdb_clean, by = "title_clean") %>%
  distinct(title_clean, platform, .keep_all = TRUE)

write_csv(title_data_clean, "data/processed/title_data_clean.csv")
