library(dplyr, warn.conflicts = FALSE)
library(readxl)
library(readr)
library(stringr)
library(forcats)


# Lookup table for the type of non--built-up areas

hnt_telepulesreszek_2018_kulterulet_jellege <- read_excel(
    path = "data-raw/hnt_2018.xls",
    sheet = "Külterület települési jellege",
    col_names = c("kulterulet_jellege", "kulterulet_jellege_nev"),
    skip = 1,
    col_types = "text"
  ) %>%
  mutate(
    kulterulet_jellege_nev = str_to_sentence(kulterulet_jellege_nev)
  )

# Lookup table for settlement part types

hnt_telepulesresz_jelleg <- read_csv(
  file = "data-raw/hnt_telepulesresz_jelleg.csv",
  col_types = "cc"
)

# Reading main table

hnt_telepulesreszek_2018 <-
  read_excel(
    path = "data-raw/hnt_2018.xls",
    sheet = "Településrészek 2018. 01. 01.",
    col_names = c("torzsszam", "telepules", "megye_kodja",
                  "telepulesresz", "telepulesresz_jelleg", "irsz",
                  "kulterulet_jellege",
                  "telepulesresz_tavolsaga_kozponti_belterulettol",
                  "nepszamlalasi_lakonepesseg", "lakasok_szama",
                  "lakott_egyeb_lakoegysegek_szama"),
    skip = 1,
    col_types = "text"
  ) %>%
  select(-megye_kodja)


# Cleaning main table

hnt_telepulesreszek_2018 <- hnt_telepulesreszek_2018 %>%
  mutate_at(
    vars(
      nepszamlalasi_lakonepesseg,
      lakasok_szama,
      lakott_egyeb_lakoegysegek_szama
    ),
    as.integer
  ) %>%
  mutate(
    telepulesresz_tavolsaga_kozponti_belterulettol = str_replace(telepulesresz_tavolsaga_kozponti_belterulettol, ",", "."),
    telepulesresz_tavolsaga_kozponti_belterulettol = as.numeric(telepulesresz_tavolsaga_kozponti_belterulettol)
  ) %>%
  left_join(hnt_telepulesresz_jelleg, by = "telepulesresz_jelleg") %>%
  mutate(telepulesresz_jelleg = factor(telepulesresz_jelleg_nev)) %>%
  select(-telepulesresz_jelleg_nev) %>%
  left_join(
    hnt_telepulesreszek_2018_kulterulet_jellege,
    by = "kulterulet_jellege"
  ) %>%
  mutate(kulterulet_jellege = factor(kulterulet_jellege_nev)) %>%
  select(-kulterulet_jellege_nev) %>%
  # Gulács village has a periphery with a separate settlement ID,
  # which isn't even in the territorial code system. As it has the
  # same postal code, we can simply drop it.
  filter(!(torzsszam == "29444" & telepules == "Gulács"))


# Saving

usethis::use_data(hnt_telepulesreszek_2018, overwrite = TRUE)
