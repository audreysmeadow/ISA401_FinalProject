source("scripts/setup.R")

tmdb_api_key <- Sys.getenv("TMDB_API_KEY")

titles <- read_csv("data/raw/movieofthenight_titles_raw.csv")

search_tmdb_title <- function(title) {

  req <- request("https://api.themoviedb.org/3/search/multi") %>%
    req_url_query(
      api_key = tmdb_api_key,
      query = title,
      language = "en-US"
    ) %>%
    req_perform()

  data <- resp_body_json(req)

  if (length(data$results) == 0) {
    return(tibble(
      title = title,
      tmdb_id = NA,
      tmdb_title = NA,
      media_type = NA,
      popularity = NA,
      vote_average = NA,
      vote_count = NA,
      release_date = NA
    ))
  }

  result <- data$results[[1]]

  tibble(
    title = title,
    tmdb_id = result$id %||% NA,
    tmdb_title = result$title %||% result$name %||% NA,
    media_type = result$media_type %||% NA,
    popularity = result$popularity %||% NA,
    vote_average = result$vote_average %||% NA,
    vote_count = result$vote_count %||% NA,
    release_date = result$release_date %||% result$first_air_date %||% NA
  )
}

tmdb_data <- titles %>%
  distinct(title) %>%
  slice_head(n = 500) %>%   # remove or increase later
  mutate(data = map(title, safely(search_tmdb_title))) %>%
  transmute(result = map(data, "result")) %>%
  unnest(result)

write_csv(tmdb_data, "data/raw/tmdb_titles_raw.csv")
