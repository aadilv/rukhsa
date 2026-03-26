library(httr2)

fetch_prayer_times <- function(city = "Toronto", country = "CA", method = 2) {
  url <- sprintf(
    "https://api.aladhan.com/v1/timingsByCity?city=%s&country=%s&method=%d",
    utils::URLencode(city), country, method
  )
  result <- tryCatch({
    resp <- request(url) |> req_timeout(6) |> req_perform()
    resp_body_json(resp)
  }, error = function(e) NULL)

  if (is.null(result) || result$code != 200) return(NULL)
  result$data$timings
}

# convert "HH:MM" 24hr string to 12hr format like "1:23 PM"
to_12hr <- function(t) {
  parts <- strsplit(t, ":")[[1]]
  h <- as.integer(parts[1])
  m <- parts[2]
  suffix <- if (h >= 12) "PM" else "AM"
  h12 <- h %% 12
  if (h12 == 0) h12 <- 12
  paste0(h12, ":", m, " ", suffix)
}

get_prayer_banner <- function(city = "Toronto", country = "CA") {
  timings <- fetch_prayer_times(city, country)
  if (is.null(timings)) return(NULL)

  now_mins <- as.integer(format(Sys.time(), "%H")) * 60 +
              as.integer(format(Sys.time(), "%M"))

  to_mins <- function(t) {
    parts <- strsplit(t, ":")[[1]]
    as.integer(parts[1]) * 60 + as.integer(parts[2])
  }

  prayers <- list(
    list(name = "Fajr",    time = to_mins(timings$Fajr),    raw = timings$Fajr),
    list(name = "Dhuhr",   time = to_mins(timings$Dhuhr),   raw = timings$Dhuhr),
    list(name = "Asr",     time = to_mins(timings$Asr),     raw = timings$Asr),
    list(name = "Maghrib", time = to_mins(timings$Maghrib), raw = timings$Maghrib),
    list(name = "Isha",    time = to_mins(timings$Isha),    raw = timings$Isha)
  )

  # find next prayer
  next_p <- NULL
  for (p in prayers) {
    if (p$time > now_mins) {
      next_p <- p
      break
    }
  }
  # after Isha - next is Fajr tmrw
  if (is.null(next_p)) next_p <- prayers[[1]]

  paste0("Next prayer: <strong>", next_p$name, " at ", to_12hr(next_p$raw), "</strong>")
}