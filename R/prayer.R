library(httr2)

# fetch by coordinates (used when browser shares location)
fetch_prayer_times_coords <- function(lat, lon, method = 2) {
  url <- sprintf(
    "https://api.aladhan.com/v1/timings?latitude=%s&longitude=%s&method=%d",
    lat, lon, method
  )
  result <- tryCatch({
    resp <- request(url) |> req_timeout(6) |> req_perform()
    resp_body_json(resp)
  }, error = function(e) NULL)
  if (is.null(result) || result$code != 200) return(NULL)
  result$data$timings
}

# fallback: guess location from IP using ip-api.com
fetch_coords_from_ip <- function() {
  result <- tryCatch({
    resp <- request("http://ip-api.com/json/?fields=lat,lon,status") |>
      req_timeout(4) |> req_perform()
    resp_body_json(resp)
  }, error = function(e) NULL)
  if (is.null(result) || result$status != "success") return(NULL)
  list(lat = result$lat, lon = result$lon)
}

to_12hr <- function(t) {
  parts <- strsplit(t, ":")[[1]]
  h  <- as.integer(parts[1])
  m  <- parts[2]
  suffix <- if (h >= 12) "PM" else "AM"
  h12 <- h %% 12
  if (h12 == 0) h12 <- 12
  paste0(h12, ":", m, " ", suffix)
}

get_prayer_banner <- function(lat = NULL, lon = NULL) {
  if (is.null(lat) || is.null(lon)) {
    coords <- fetch_coords_from_ip()
    if (is.null(coords)) return(NULL)
    lat <- coords$lat
    lon <- coords$lon
  }

  timings <- fetch_prayer_times_coords(lat, lon)
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

  next_p <- NULL
  for (p in prayers) {
    if (p$time > now_mins) { next_p <- p; break }
  }
  if (is.null(next_p)) next_p <- prayers[[1]]

  paste0("Next prayer: <strong>", next_p$name, " at ", to_12hr(next_p$raw), "</strong>")
}