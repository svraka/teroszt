library(dplyr, warn.conflicts = FALSE)
library(forcats)
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
         irsz = if_else(telepules == "Szalmatercs", "3163", irsz),
         # Determine the main settlement for each post code by finding
         # the "biggest" post office assigned to a code using the
         # following hierarchy. Needs some further cleaning to
         # harmonize with other sources.
         tipus = case_when(
           # Proper office
           str_detect(nev, regex(" posta*$", ignore_case = TRUE))     ~ 1,
           # branch office
           str_detect(nev, regex("kirendeltség", ignore_case = TRUE)) ~ 2,
           # Shops providing postal services
           str_detect(nev, regex("postapartner", ignore_case = TRUE)) ~ 3,
           # Mobile offices
           nev == "mobilposta"                                        ~ 4,
           # The rest, currently includes a single parcel delivery point
           TRUE                                                       ~ 5)
         ) %>%
  arrange(irsz, tipus) %>%
  group_by(irsz) %>%
  mutate(postahivatal_fo_telepules = head(telepules, 1)) %>%
  ungroup() %>%
  # Manual cleaning for some edge cases
  mutate(postahivatal_fo_telepules = if_else(irsz == "7461", "Kaposvár",
                                             postahivatal_fo_telepules),
         postahivatal_fo_telepules = if_else(irsz == "4337", "Jármi",
                                             postahivatal_fo_telepules),
         postahivatal_fo_telepules = if_else(irsz == "8960", "Lenti",
                                             postahivatal_fo_telepules)) %>%
  distinct(telepules, irsz, postahivatal_fo_telepules)


# Constructing all valid postal codes

irsz_posta_2018 <- bind_rows(
    irsz_posta_2018_sima,
    irsz_posta_2018_utcajegyzekbol,
    irsz_postahivatalok,
  ) %>%
  arrange(irsz) %>%
  select(-telepulesresz) %>%
  mutate(postahivatal_fo_telepules = replace_na(postahivatal_fo_telepules, "0")) %>%
  group_by(irsz) %>%
  mutate(postahivatal_fo_telepules = max(postahivatal_fo_telepules)) %>%
  distinct(irsz, telepules, postahivatal_fo_telepules) %>%
  nest(irsz = c(irsz, postahivatal_fo_telepules))


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
    # Harmonize Budapest districts' names with the code system
    telepules = if_else(str_detect(telepules, "Budapest"),
                        str_replace(telepules, "kerület", "ker."),
                        telepules),
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
  # Both postal codes are used on other parts of the settlement, and
  # only used in Zalaszentgrót, so we can drop it.
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
  mutate(postahivatal_fo_telepules = "0") %>%
  nest(irsz = c(irsz, postahivatal_fo_telepules))


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
  group_by(irsz) %>%
  mutate(postahivatal_fo_telepules = max(postahivatal_fo_telepules,
                                         na.rm = TRUE)) %>%
  ungroup() %>%
  distinct(torzsszam, telepules, irsz, postahivatal_fo_telepules) %>%
  filter(!is.na(irsz))

load("data/tsz_2018.rda")
load("data/hnt_telepulesreszek_2018.rda")

# Find all settlements which have post codes reaching across
# settlement boundaries. We'll use borough level population to assign
# main settlement to each post code and thus we won't consider
# overlaps that do not come up in the Gazetteer. We'll fix that
# separately.
irsz_2018_tofix <- irsz_2018_prep %>%
  distinct(torzsszam, telepules, irsz) %>%
  group_by(irsz) %>%
  mutate(problema = length(unique(torzsszam))) %>%
  ungroup() %>%
  mutate(javitas = if_else(problema == 1, "nincs_jav", "jav_hnt")) %>%
  group_split(javitas) %>%
  set_names(map(., ~ unique(.x$javitas))) %>%
  map(~ select(.x, -javitas))

irsz_2018_tofix$jav_hnt <- irsz_2018_tofix$jav_hnt %>%
  # In Budapest normal post codes don't cause issues, only post office
  # based codes.
  filter(!str_detect(telepules, "Budapest")) %>%
  arrange(irsz) %>%
  distinct(torzsszam) %>%
  left_join(full_join(hnt_telepulesreszek_2018,
                      hnt_irsz_2018 %>% unnest(cols = irsz) %>% select(-postahivatal_fo_telepules),
                      by = c("torzsszam", "telepules", "irsz")),
            by = "torzsszam") %>%
  select(torzsszam, telepules, telepulesresz_jelleg, irsz,
         nepesseg = nepszamlalasi_lakonepesseg) %>%
  arrange(irsz, telepules) %>%
  select(irsz, telepules, everything()) %>%
  group_by(irsz, telepules, torzsszam, telepulesresz_jelleg) %>%
  summarise(n_telepulesresz = n(),
            nepesseg = sum(nepesseg, na.rm = TRUE),
            .groups = "drop") %>%
  group_by(irsz) %>%
  mutate(problemas = length(unique(torzsszam))) %>%
  ungroup() %>%
  mutate(telepulesresz_jelleg = replace_na(telepulesresz_jelleg,
                                           "Külterület")) %>%
  filter(problemas != 1)

irsz_2018_tofix$jav_nem_hnt <- irsz_2018_prep %>%
  distinct(torzsszam, telepules, irsz, postahivatal_fo_telepules) %>%
  group_by(irsz) %>%
  mutate(problema = length(unique(torzsszam))) %>%
  ungroup() %>%
  filter(problema != 1) %>%
  anti_join(irsz_2018_tofix$jav_hnt, by = "irsz") %>%
  left_join(hnt_telepulesreszek_2018 %>% distinct(irsz, torzsszam),
            by = c("torzsszam", "irsz")) %>%
  arrange(irsz) %>%
  group_by(irsz)

# Check partitioning
irsz_2018_tofix_nrows <- map_int(irsz_2018_tofix,
                             ~ nrow(distinct(.x, torzsszam, telepules, irsz)))
irsz_partitions <- map(irsz_2018_tofix, ~ unique(.x$irsz))
stopifnot(nrow(irsz_2018_prep) == sum(irsz_2018_tofix_nrows))
stopifnot(intersect(irsz_partitions[[1]], irsz_partitions[[2]]) == character(0))
stopifnot(intersect(irsz_partitions[[1]], irsz_partitions[[3]]) == character(0))
stopifnot(intersect(irsz_partitions[[2]], irsz_partitions[[3]]) == character(0))

# Apply futher cleaning
irsz_2018_fixed <- irsz_2018_tofix

# Find the primary settlement -- based on population size -- that uses
# a particular post code for the case when we have multiple boroughs
# from the Gazetteer.
irsz_2018_fixed$jav_hnt <- irsz_2018_tofix$jav_hnt %>%
  arrange(irsz, desc(nepesseg)) %>%
  group_by(irsz) %>%
  mutate(torzsszam_fo_telepules = head(torzsszam, 1)) %>%
  ungroup() %>%
  select(torzsszam, telepules, irsz, torzsszam_fo_telepules) %>%
  distinct(torzsszam, telepules, irsz, torzsszam_fo_telepules)

# We already did all the cleaning when reading the post office table,
# we just need to add IDs
irsz_2018_fixed$jav_nem_hnt <- irsz_2018_fixed$jav_nem_hnt %>%
  mutate(torzsszam_fo_telepules = if_else(telepules == postahivatal_fo_telepules,
                                          torzsszam,
                                          NA_character_)) %>%
  group_by(irsz) %>%
  mutate(torzsszam_fo_telepules = max(torzsszam_fo_telepules, na.rm = TRUE)) %>%
  select(torzsszam, telepules, irsz, torzsszam_fo_telepules)

# These are the cases without any boundary-crossing post codes, just
# add a column indicating that.
irsz_2018_fixed$nincs_jav <- irsz_2018_fixed$nincs_jav %>%
  select(-problema) %>%
  mutate(torzsszam_fo_telepules = torzsszam)

# And create the final table
irsz_2018 <- irsz_2018_fixed %>%
  bind_rows() %>%
  arrange(irsz, torzsszam)

# Basic consistency checks
stopifnot(map_int(irsz_2018, ~ sum(is.na(.x))) == rep(0, ncol(irsz_2018)))
stopifnot(nrow(irsz_2018) == nrow(distinct(irsz_2018, torzsszam, telepules, irsz)))

# Check that we fixed all problems in post codes crossing settlement
# boundaries.
irsz_2018_check <- irsz_2018 %>%
  group_by(irsz) %>%
  summarise(ell = length(unique(torzsszam_fo_telepules)), .groups = "drop") %>%
  filter(ell != 1)
stopifnot(nrow(irsz_2018_check) == 0)

# Saving

usethis::use_data(irsz_2018, overwrite = TRUE)
