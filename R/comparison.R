library(dplyr)
library(stringr)

build_comparison <- function(db, question) {
  stop_words <- c("how", "do", "i", "to", "the", "a", "an", "is", "can",
                  "what", "does", "in", "for", "my", "me", "with", "and",
                  "or", "it", "this", "that", "should", "would", "could",
                  "have", "has", "be", "are", "was", "were", "will", "when")

  keywords <- question |>
    tolower() |>
    str_replace_all("[^a-z ]", " ") |>
    str_split("\\s+") |>
    unlist() |>
    (\(x) x[nchar(x) > 2 & !x %in% stop_words])()

  if (length(keywords) == 0) return(NULL)

  pattern <- paste(keywords, collapse = "|")

  result <- db |>
    mutate(
      score =
        (str_detect(tolower(condition_topic), pattern) * 2) +
        (str_detect(tolower(app_display_tag), pattern) * 2) +
        (str_detect(tolower(ruling_summary),  pattern) * 1)
    ) |>
    filter(score > 0) |>
    group_by(madhab) |>
    slice_max(score, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(madhab, condition_topic, ruling_summary, cross_madhab_note)

  if (nrow(result) == 0) return(NULL)
  return(result)
}