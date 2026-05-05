source("scripts/setup.R")

titles <- read_csv("data/processed/title_data_clean.csv")
platforms <- read_csv("data/processed/platform_data_clean.csv")

final_dataset <- titles %>%
  left_join(platforms, by = "platform") %>%
  mutate(
    popularity = replace_na(popularity, 0),
    vote_average = replace_na(vote_average, 0),
    vote_count = replace_na(vote_count, 0)
  )

write_csv(final_dataset, "data/processed/final_streaming_dataset.csv")
