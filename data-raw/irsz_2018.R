library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(purrr)
library(readxl)
library(tidyr)
library(janitor, warn.conflicts = FALSE)



# Postal code from the Post Office

irsz_posta_file <- "data-raw/iranyitoszam_2019-01-15.xlsx"

# Regular postal codes

irsz_posta_2018_sima <- read_excel(irsz_posta_file, col_types = "text") %>%
  clean_names %>%
  mutate(telepules = str_remove(telepules, "\\*"))

# Postal codes based on street addresses (for large cities)

re_utca <- "[\\ \\.]u\\."

irsz_posta_2018_utcajegyzekbol <- excel_sheets(irsz_posta_file) %>%
  str_subset(re_utca) %>%
  set_names %>%
  map_dfr(
    ~read_excel(irsz_posta_file, sheet = ., col_types = "text") %>% clean_names,
    .id = "telepules"
  ) %>%
  select(telepules, irsz) %>%
  distinct %>%
  mutate(
    telepules = str_remove(telepules, re_utca),
    telepules = str_replace(telepules, "^Bp$", "Budapest")
  ) %>%
  arrange_all

# Constructing all valid postal codes

irsz_posta_2018 <- bind_rows(
    irsz_posta_2018_sima,
    irsz_posta_2018_utcajegyzekbol
  ) %>%
  arrange(irsz) %>%
  mutate(
    # Unify Budapest districts names with the Gazetteer's form
    telepules = if_else(
      telepules == "Budapest",
      str_c(
        telepules,
        str_replace(irsz, "\\d(\\d{2})\\d", "\\1."),
        "kerület",
        sep = " "
      ),
      telepules
    ),
    # Margit-szigetnek in Budapest has its own postal code
    telepules = if_else(irsz == "1007", "Budapest", telepules)
  ) %>%
  select(-telepulesresz) %>%
  group_by(telepules) %>%
  nest(.key = "irsz")


# Postal codes from the Gazetteer

# Regular

hnt_irsz_2018_kieg <- read_excel(
  path = "data-raw/hnt_2018.xls",
  sheet = "Megj. postai ir. számhoz",
  col_types = "text"
) %>%
  clean_names %>%
  rename(torzsszam = helyseg_ksh_kod) %>%
  mutate(
    torzsszam = str_pad(torzsszam, width = 5, pad = "0")
  ) %>%
  group_by(torzsszam) %>%
  mutate(
    irsz = str_extract_all(megjegyzes_a_postai_iranyitoszamhoz, "\\d{4}")
  ) %>%
  select(-megjegyzes_a_postai_iranyitoszamhoz) %>%
  unnest

# Street address based ones

load("data/hnt_telepulesreszek_2018.rda")

hnt_telepulesreszek_2018 <- hnt_telepulesreszek_2018 %>%
  select(torzsszam, telepules, irsz, kulterulet_jellege) %>%
  mutate(
    kulterulet = !is.na(kulterulet_jellege),
    # In Budapesten all postal codes are address based, so we don't
    # have to deal with non--built-up areeas.
    kulterulet = replace(
      kulterulet,
      str_detect(telepules, "Budapest"),
      FALSE
    )
  ) %>%
  select(-kulterulet_jellege) %>%
  distinct %>%
  # Zalaszentgrót has a settlement part with a duplicated postal code.
  # Both postal codes are used on other parts of the settlement, so we
  # can drop it.
  filter(irsz != "8790/8795") %>%
  mutate(irsz = if_else(irsz == "*", NA_character_, irsz)) %>%
  # Flag the settlement parts which have their own postal codes and
  # this codes is only used by this part.
  group_by(torzsszam, telepules, irsz) %>%
  summarise(csak_kulterulet = as.logical(min(kulterulet)))

# Merging

hnt_irsz_2018 <- hnt_telepulesreszek_2018 %>%
  full_join(hnt_irsz_2018_kieg, by = c("torzsszam", "irsz")) %>%
  arrange(torzsszam) %>%
  group_by(torzsszam) %>%
  fill(telepules) %>%
  ungroup %>%
  arrange(telepules) %>%
  group_by(torzsszam, telepules) %>%
  nest(.key = "irsz")


# Merging the Post Office's and the Statistical Office's data

# Consistency check

stopifnot(nrow(irsz_posta_2018) == nrow(hnt_irsz_2018))

# All settlement have pairs based on names but postal codes can
# differ. Here we unify them.

collapse_irsz <- function(df) {
  df %>%
    filter(!is.na(irsz)) %>%
    mutate(
      csak_kulterulet = replace_na(csak_kulterulet, FALSE)
    ) %>%
    group_by(irsz) %>%
    summarise(csak_kulterulet = as.logical(min(csak_kulterulet)))
}


irsz_2018 <- hnt_irsz_2018 %>%
  full_join(irsz_posta_2018, by = "telepules") %>%
  group_by(torzsszam, telepules) %>%
  mutate(
    irsz = map2(irsz.x, irsz.y, bind_rows),
    irsz = map(irsz, collapse_irsz)
  ) %>%
  select(-irsz.x, -irsz.y) %>%
  unnest %>%
  ungroup %>%
  arrange(torzsszam, irsz)


# Saving

usethis::use_data(irsz_2018, overwrite = TRUE)
