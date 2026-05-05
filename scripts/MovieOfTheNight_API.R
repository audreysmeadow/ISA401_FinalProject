source("scripts/setup.R")

services <- c(
  "netflix",
  "disney",
  "max",
  "hulu",
  "prime",
  "peacock",
  "paramount",
  "apple"
)

# Placeholder structure until API endpoint is finalized
movieofthenight_titles <- tibble(
  title = character(),
  platform = character(),
  type = character(),
  movieofthenight_id = character()
)

# Example pseudo-loop
# Replace URL and parameters with actual Movie Of The Night API details
for (service in services) {

  message("Collecting titles for: ", service)

  # req <- request("MOVIE_OF_THE_NIGHT_ENDPOINT") %>%
  #   req_url_query(service = service) %>%
  #   req_perform()
  #
  # data <- resp_body_json(req)
  #
  # service_titles <- tibble(
  #   title = map_chr(data$results, "title"),
  #   platform = service,
  #   type = map_chr(data$results, "type"),
  #   movieofthenight_id = map_chr(data$results, "id")
  # )
  #
  # movieofthenight_titles <- bind_rows(movieofthenight_titles, service_titles)
}

write_csv(movieofthenight_titles, "data/raw/movieofthenight_titles_raw.csv")
