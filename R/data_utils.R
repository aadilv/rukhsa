library(readxl)
library(dplyr)

load_fiqh_data <- function(data_dir = "data") {
  files <- list(
    file.path(data_dir, "hanafi_fiqh.xlsx"),
    file.path(data_dir, "maliki_fiqh.xlsx"),
    file.path(data_dir, "hanbali_fiqh.xlsx"),
    file.path(data_dir, "shafii_fiqh.xlsx")
  )

  dfs <- lapply(files, function(path) {
    read_excel(path, col_types = "text")
  })

  combined <- bind_rows(dfs)
  return(combined)
}

filter_by_madhab <- function(df, selected_madhab) {
  df %>% filter(madhab == selected_madhab)
}