library(httr2)

parse_quran_ref <- function(ref_string) {
  if (is.null(ref_string) || is.na(ref_string) || nchar(trimws(ref_string)) == 0) return(NULL)
  first <- trimws(strsplit(ref_string, ";")[[1]][1])
  m <- regmatches(first, regexpr("\\d+:\\d+", first))
  if (length(m) == 0 || nchar(m) == 0) return(NULL)
  m
}

fetch_quran_verse <- function(ref) {
  url <- paste0("https://api.alquran.cloud/v1/ayah/", ref, "/en.pickthall")
  result <- tryCatch({
    resp <- request(url) |>
      req_timeout(10) |>
      req_error(is_error = function(resp) FALSE) |>
      req_perform()
    if (resp_status(resp) != 200) return(NULL)
    resp_body_json(resp)
  }, error = function(e) NULL)
  if (is.null(result) || is.null(result$code) || result$code != 200) return(NULL)
  text  <- result$data$text
  surah <- result$data$surah$englishName
  if (is.null(text) || nchar(trimws(text)) == 0) return(NULL)
  list(text = trimws(text), ref = paste0(surah, " ", ref))
}

get_quran_verses <- function(quranic_evidence) {
  if (is.null(quranic_evidence) || is.na(quranic_evidence) ||
      nchar(trimws(quranic_evidence)) == 0) return(list())
  parts <- trimws(strsplit(quranic_evidence, ";")[[1]])
  parts <- head(parts, 2)
  verses <- list()
  for (p in parts) {
    ref <- parse_quran_ref(p)
    if (is.null(ref)) next
    v <- tryCatch(fetch_quran_verse(ref), error = function(e) NULL)
    if (!is.null(v)) verses <- c(verses, list(v))
  }
  verses
}