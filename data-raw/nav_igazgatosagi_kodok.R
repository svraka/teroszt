library(readr)
library(dplyr, warn.conflicts = FALSE)
library(forcats)

nav_igazgatosagi_kodok <- read_csv(
  file = "data-raw/nav_igazgatosagi_kodok.csv",
  col_types = "ccccc"
)


# Set factor levels for code labels. This keeps their commonly used
# ordering based on their coding systems instead of simple
# alphabetical sorting. In this case we follow counties' coding and
# use NTCA codes only for to disambiguate directorates in Budapest.

nav_igazgatosagi_kodok <- nav_igazgatosagi_kodok %>%
  mutate(nav_ig_nev = fct_inorder(nav_ig_nev))

usethis::use_data(nav_igazgatosagi_kodok, overwrite = TRUE)
