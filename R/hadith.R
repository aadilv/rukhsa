# R/hadith.R
# fetches hadith text from fawazahmed0/hadith-api (no key, CDN-served)

library(httr2)

collection_to_edition <- function(collection) {
  map <- list(
    "bukhari"  = "eng-bukhari",
    "muslim"   = "eng-muslim",
    "abudawud" = "eng-abudawud",
    "dawud"    = "eng-abudawud",
    "tirmidhi" = "eng-tirmidhi",
    "ibnmajah" = "eng-ibnmajah",
    "majah"    = "eng-ibnmajah",
    "nasai"    = "eng-nasai"
  )
  map[[tolower(trimws(collection))]]
}

parse_hadith_ref <- function(ref_string) {
  m <- regmatches(ref_string,
    regexpr("(bukhari|muslim|abu\\s*dawud|tirmidhi|ibn\\s*majah|nasai)\\s+(\\d+)",
            ref_string, ignore.case = TRUE, perl = TRUE))
  if (length(m) == 0 || m == "") return(NULL)
  parts      <- strsplit(trimws(m), "\\s+")[[1]]
  number     <- tail(parts, 1)
  collection <- gsub("\\s", "", tolower(paste(head(parts, -1), collapse = "")))
  edition    <- collection_to_edition(collection)
  if (is.null(edition)) return(NULL)
  list(edition = edition, number = number)
}

fetch_hadith <- function(edition, number) {
  url <- sprintf(
    "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/%s/%s.json",
    edition, number
  )
  result <- tryCatch({
    resp <- request(url) |> req_timeout(8) |> req_perform()
    resp_body_json(resp)
  }, error = function(e) NULL)
  if (is.null(result)) return(NULL)
  text <- result$hadith[[1]]$text
  if (is.null(text) || nchar(trimws(text)) == 0) return(NULL)
  trimws(text)
}

get_hadith_text <- function(hadith_evidence) {
  if (is.na(hadith_evidence) || nchar(trimws(hadith_evidence)) == 0) return(NULL)
  parsed <- parse_hadith_ref(hadith_evidence)
  if (is.null(parsed)) return(NULL)
  fetch_hadith(parsed$edition, parsed$number)
}