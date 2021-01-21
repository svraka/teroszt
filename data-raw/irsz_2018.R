library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(purrr)
library(readxl)
library(tidyr)


# Postal code from the Post Office

irsz_posta_file <- "data-raw/iranyitoszam_2019-01-15.xlsx"

# Regular postal codes

irsz_posta_2018_sima <-
  read_excel(irsz_posta_file,
             col_names = c("irsz", "telepules", "telepulesresz"),
             skip = 2,
             col_types = "text") %>%
  mutate(telepules = str_remove(telepules, "\\*"))

# Postal codes based on street addresses (for large cities)

re_utca <- "[\\ \\.]u\\."

irsz_posta_2018_utcajegyzekbol <- excel_sheets(irsz_posta_file) %>%
  str_subset(re_utca) %>%
  set_names() %>%
  map_dfr(
    ~ read_excel(irsz_posta_file, sheet = ., col_types = "text"),
    .id = "telepules"
  ) %>%
  select(telepules, IRSZ, KER) %>%
  rename_with(.fn = tolower, .cols = everything()) %>%
  distinct() %>%
  mutate(
    telepules = str_remove(telepules, re_utca),
    ker_int = if_else(ker %in% c("Margitsziget", "0"), NA_character_, ker),
    ker_int = str_remove(ker_int, "\\.") %>% as.roman() %>% as.integer(),
    ker_int = str_pad(ker_int, width = 2, side = "left", pad = "0"),
    telepules = case_when(
      telepules == "Bp" & !is.na(ker_int) ~ sprintf("Budapest %s. ker.", ker_int),
      telepules == "Bp" & is.na(ker_int)  ~ "Budapest",
      TRUE                                ~ telepules
    )
  ) %>%
  select(-ker, -ker_int) %>%
  arrange_all()

# Post office addresses

# Convert Budapest districts' names to arabic numerals
convert_kerulet <- function(x) {
  string_roman <- x %>%
    str_extract("Budapest\\ .+\\.\\ ker\\.$") %>%
    str_replace("Budapest\\ (.+)\\.\\ ker\\.$", "\\1")

  arabic <- string_roman %>% as.roman %>% as.integer
  padded <- str_pad(arabic, width = 2, pad = "0")
  string <- str_c("Budapest ", padded, ". ker.")

  string
}

irsz_postahivatalok <-
  read_excel(
    path = here::here("data-raw", "Allando_postai_szolgaltatohelyek.xlsx"),
    guess_max = 10000
  ) %>%
  select(1, 3, 4, 5) %>%
  set_names(c("telepules", "nev", "irsz", "cim")) %>%
  mutate(irsz = as.character(as.integer(irsz)),
         telepules = if_else(str_detect(telepules, "Budapest"),
                             convert_kerulet(telepules), telepules),
         # Definitely typo
         irsz = if_else(telepules == "Monyoród", "7751", irsz),
         # Likely typo
         irsz = if_else(telepules == "Lúzsok", "7838", irsz),
         # Maybe typo?
         irsz = if_else(telepules == "Szalmatercs", "3163", irsz)) %>%
  distinct(telepules, irsz)


# Constructing all valid postal codes

irsz_posta_2018 <- bind_rows(
    irsz_posta_2018_sima,
    irsz_posta_2018_utcajegyzekbol,
    irsz_postahivatalok
  ) %>%
  arrange(irsz) %>%
  mutate(
    # Unify Budapest districts names with the Gazetteer's form
    telepules = str_replace(telepules,
                            "(Budapest\\ \\d+\\.\\ )ker\\.",
                            "\\1kerület")
  ) %>%
  select(-telepulesresz) %>%
  distinct() %>%
  nest(irsz = c(irsz))


# Postal codes from the Gazetteer

# Regular

hnt_irsz_2018_kieg <-
  read_excel(
    path = "data-raw/hnt_2018.xls",
    sheet = "Megj. postai ir. számhoz",
    col_names = c("torzsszam", "megjegyzes_a_postai_iranyitoszamhoz"),
    skip = 1,
    col_types = "text"
  ) %>%
  mutate(
    torzsszam = str_pad(torzsszam, width = 5, pad = "0")
  ) %>%
  group_by(torzsszam) %>%
  mutate(
    irsz = str_extract_all(megjegyzes_a_postai_iranyitoszamhoz, "\\d{4}")
  ) %>%
  select(-megjegyzes_a_postai_iranyitoszamhoz) %>%
  unnest(cols = c(irsz))

# Street address based ones

load("data/hnt_telepulesreszek_2018.rda")

hnt_telepulesreszek_2018 <- hnt_telepulesreszek_2018 %>%
  select(torzsszam, telepules, irsz, kulterulet_jellege) %>%
  mutate(
    kulterulet = !is.na(kulterulet_jellege),
    # In Budapest all postal codes are address based, so we don't
    # have to deal with non--built-up areas.
    kulterulet = replace(
      kulterulet,
      str_detect(telepules, "Budapest"),
      FALSE
    )
  ) %>%
  select(-kulterulet_jellege) %>%
  distinct() %>%
  # Zalaszentgrót has a settlement part with a duplicated postal code.
  # Both postal codes are used on other parts of the settlement, so we
  # can drop it.
  filter(irsz != "8790/8795") %>%
  mutate(irsz = if_else(irsz == "*", NA_character_, irsz)) %>%
  distinct(torzsszam, telepules, irsz)

# Merging

hnt_irsz_2018 <- hnt_telepulesreszek_2018 %>%
  full_join(hnt_irsz_2018_kieg, by = c("torzsszam", "irsz")) %>%
  arrange(torzsszam) %>%
  group_by(torzsszam) %>%
  fill(telepules) %>%
  ungroup() %>%
  arrange(telepules) %>%
  nest(irsz = c(irsz))


# Merging the Post Office's and the Statistical Office's data

# Consistency check

stopifnot(nrow(irsz_posta_2018) == nrow(hnt_irsz_2018))

# All settlement have pairs based on names but postal codes can
# differ. Here we unify them.

irsz_2018_prep <- hnt_irsz_2018 %>%
  full_join(irsz_posta_2018, by = "telepules") %>%
  group_by(torzsszam, telepules) %>%
  mutate(irsz = map2(irsz.x, irsz.y, bind_rows)) %>%
  select(-irsz.x, -irsz.y) %>%
  unnest(cols = c(irsz)) %>%
  ungroup() %>%
  distinct(torzsszam, telepules, irsz) %>%
  arrange(torzsszam, irsz) %>%
  filter(!is.na(irsz))

load("data/tsz_2018.rda")
load("data/hnt_telepulesreszek_2018.rda")

# Find all settlements that have boroughs reaching across county
# boundaries. This leaves out overlaps that do not come up in the
# Gazetteer but we can assume those should not be problematic.
#
# TODO: The same logic can be applied to postcodes crossing district,
# or even settlement boundaries but that requires more manual
# checking.

problemas_megye <- irsz_2018_prep %>%
  left_join(
    tsz_2018 %>% select(torzsszam, megye, megye_nev),
    by = "torzsszam"
  ) %>%
  # In Budapest all the potential problems arise from NA and `*`
  # postcodes, and we don't have to deal with that here.
  filter(!str_detect(telepules, "Budapest")) %>%
  distinct(torzsszam, telepules, irsz, megye, megye_nev) %>%
  group_by(irsz) %>%
  mutate(problema = length(unique(megye))) %>%
  ungroup() %>%
  filter(problema != 1) %>%
  arrange(irsz) %>%
  distinct(torzsszam) %>%
  left_join(full_join(hnt_telepulesreszek_2018,
                      hnt_irsz_2018 %>% unnest(cols = irsz),
                      by = c("torzsszam", "telepules", "irsz")),
            by = "torzsszam") %>%
  left_join(tsz_2018 %>% distinct(torzsszam, megye, megye_nev),
            by = "torzsszam") %>%
  select(torzsszam, telepules, megye, megye_nev, telepulesresz_jelleg,
         irsz, nepesseg = nepszamlalasi_lakonepesseg) %>%
  arrange(irsz, telepules) %>%
  select(irsz, telepules, everything()) %>%
  group_by(irsz, telepules, torzsszam, telepulesresz_jelleg, megye, megye_nev) %>%
  summarise(n_telepulesresz = n(),
            nepesseg = sum(nepesseg, na.rm = TRUE),
            .groups = "drop") %>%
  group_by(irsz) %>%
  mutate(problemas = length(unique(torzsszam))) %>%
  ungroup() %>%
  filter(problemas != 1)

# And set a settlement for these problematic postcodes for the purpose
# of postcode-county crosswalks.
irsz_torzsszam_jav <- problemas_megye %>%
  select(-problemas) %>%
  arrange(irsz, desc(nepesseg)) %>%
  mutate(fo_telepules_kozponti = if_else(telepulesresz_jelleg == "Központi belterület",
                                         torzsszam, "00000"),
         fo_telepules_egyeb = if_else(telepulesresz_jelleg == "Egyéb belterület",
                                      torzsszam, "00000")) %>%
  group_by(irsz) %>%
  mutate(fo_telepules_kozponti = max(fo_telepules_kozponti, na.rm = TRUE),
         fo_telepules_egyeb = max(fo_telepules_egyeb, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(torzsszam_fo_telepules = fo_telepules_kozponti,
         torzsszam_fo_telepules = if_else(torzsszam_fo_telepules == "00000",
                                          fo_telepules_egyeb,
                                          fo_telepules_kozponti)) %>%
  select(-fo_telepules_kozponti, -fo_telepules_egyeb)

irsz_torzsszam_jav_kapcs <- irsz_torzsszam_jav %>%
  distinct(irsz, torzsszam = torzsszam_fo_telepules) %>%
  left_join(tsz_2018 %>% distinct(torzsszam, megye_jav = megye),
            by = "torzsszam") %>%
  select(-torzsszam)

irsz_2018 <- irsz_2018_prep %>%
  left_join(tsz_2018 %>% distinct(torzsszam, megye),
            by = "torzsszam") %>%
  left_join(irsz_torzsszam_jav_kapcs, by = "irsz") %>%
  mutate(megye = coalesce(megye_jav, megye)) %>%
  select(torzsszam, telepules, irsz, megye) %>%
  # Manual fixes:
  #
  # Lőrinci and Héhalom share postcodes in two non--build-up areas.
  # Keep Héhalom's county, as that is a proper settlement part.
  mutate(megye = if_else(irsz == "3024", "12", megye))

# Check that we fixed all problems in post codes crossing county
# boundaries.
irsz_2018_check <- irsz_2018 %>%
  group_by(irsz) %>%
  summarise(ell = length(unique(megye)), .groups = "drop") %>%
  filter(ell != 1)
stopifnot(nrow(irsz_2018_check) == 0)

stopifnot(all(!is.na(irsz_2018$irsz)))
stopifnot(all(!is.na(irsz_2018$megye)))

# Saving

usethis::use_data(irsz_2018, overwrite = TRUE)
