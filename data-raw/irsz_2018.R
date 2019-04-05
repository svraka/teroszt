library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(purrr)
library(readxl)
library(tidyr)
library(asmisc)



# Iranyitoszamok Postatol

irsz_posta_file <- "data-raw/iranyitoszam_2019-01-15.xlsx"

# Sima

irsz_posta_2018_sima <- read_excel(irsz_posta_file, col_types = "text") %>%
  clean_names %>%
  mutate(telepules = str_remove(telepules, "\\*"))

# Utcajegyzekes

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

# Osszes valid iranyitoszam

irsz_posta_2018 <- bind_rows(
    irsz_posta_2018_sima,
    irsz_posta_2018_utcajegyzekbol
  ) %>%
  arrange(irsz) %>%
  mutate(
    # Budapesti keruletek nevenek egysegesitese a HNT-vel
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
    # Margit-szigetnek sajat iranyitoszama van
    telepules = if_else(irsz == "1007", "Budapest", telepules)
  ) %>%
  group_by(telepules) %>%
  summarise(irsz = list(irsz))


# Iranyitoszamok a HNT-bol

# Utcajegyzekesek

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

# Simak

load("data/hnt_telepulesreszek_2018.rda")

hnt_telepulesreszek_2018 <- hnt_telepulesreszek_2018 %>%
  select(torzsszam, telepules, irsz) %>%
  distinct %>%
  # Zalaszentgróton van egy dupla iranyitoszamos telepulesresz.  Mindket iranyitszam hasznalt mas telepulesreszen is, igy dobjuk
  filter(irsz != "8790/8795") %>%
  mutate(irsz = if_else(irsz == "*", NA_character_, irsz))

# Egybe

hnt_irsz_2018 <- hnt_telepulesreszek_2018 %>%
  full_join(hnt_irsz_2018_kieg, by = c("torzsszam", "irsz")) %>%
  arrange(torzsszam) %>%
  group_by(torzsszam) %>%
  fill(telepules) %>%
  ungroup %>%
  arrange(telepules) %>%
  group_by(torzsszam, telepules) %>%
  summarise(irsz = list(irsz)) %>%
  ungroup


# Postai es KSH osszeolvasztasa

# Ellenorzes

stopifnot(nrow(irsz_posta_2018) == nrow(hnt_irsz_2018))

# Minden telepulesnek van parja nev szerint, de vannak kulonbozo iranyitoszamok.
# Ezeket egysegesitjuk

irsz_2018 <- hnt_irsz_2018 %>%
  full_join(irsz_posta_2018, by = "telepules") %>%
  group_by(torzsszam, telepules) %>%
  mutate(
    irsz = list(append(irsz.x, irsz.y, after = length(irsz.x))),
    irsz = list(unlist(irsz)),
    irsz = map(irsz, ~discard(., is.na)),
    irsz = map(irsz, unique)
  ) %>%
  select(-irsz.x, -irsz.y) %>%
  unnest %>%
  ungroup %>%
  arrange(torzsszam, irsz)


# Mentes

usethis::use_data(irsz_2018, overwrite = TRUE)
