source("scripts/setup.R")

data <- read_csv("data/processed/final_streaming_dataset.csv")

platform_summary <- data %>%
  group_by(platform) %>%
  summarise(
    monthly_price = first(monthly_price),
    catalog_size = n_distinct(title_clean),
    total_popularity = sum(popularity, na.rm = TRUE),
    avg_popularity = mean(popularity, na.rm = TRUE),
    avg_rating = mean(vote_average, na.rm = TRUE),
    total_votes = sum(vote_count, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    titles_per_dollar = catalog_size / monthly_price,
    popularity_per_dollar = total_popularity / monthly_price,
    popularity_per_title = total_popularity / catalog_size,

    value_score = scale(titles_per_dollar)[,1] +
      scale(popularity_per_dollar)[,1] +
      scale(popularity_per_title)[,1],

    rank = dense_rank(desc(value_score))
  ) %>%
  arrange(rank)

write_csv(platform_summary, "outputs/summary_tables/platform_value_summary.csv")

ggplot(platform_summary, aes(x = reorder(platform, value_score), y = value_score)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Streaming Service Value Score by Platform",
    x = "Platform",
    y = "Value Score"
  )

ggsave("outputs/figures/value_score_by_platform.png", width = 9, height = 6)
