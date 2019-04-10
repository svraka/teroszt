library(readr)

nav_igazgatosagi_kodok <- read_csv(
  file = "data-raw/nav_igazgatosagi_kodok.csv",
  col_types = "ccccc"
)

usethis::use_data(nav_igazgatosagi_kodok, overwrite = TRUE)
