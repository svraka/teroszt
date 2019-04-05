library(dplyr, warn.conflicts = FALSE)
library(readxl)
library(readr)
library(stringr)
library(forcats)
library(asmisc)


# Kapcsolotabla a kulterulet jellege megnevezesekhez

hnt_telepulesreszek_2018_kulterulet_jellege <- read_excel(
    path = "data-raw/hnt_2018.xls",
    sheet = "Külterület települési jellege",
    col_types = "text"
  ) %>%
  clean_names %>%
  rename(
    kulterulet_jellege = rovidites,
    kulterulet_jellege_nev = kulterulet_telepulesi_jellege,
  ) %>%
  mutate(
    kulterulet_jellege_nev = str_to_sentence(kulterulet_jellege_nev)
  )

# Kapcsolotabla a telepulesresz jellege megnevezesekhez

hnt_telepulesresz_jelleg <- read_csv(
  file = "data-raw/hnt_telepulesresz_jelleg.csv",
  col_types = "cc"
)

# Telepulesreszek tabla beolvasasa

hnt_telepulesreszek_2018 <- read_excel(
    path = "data-raw/hnt_2018.xls",
    sheet = "Településrészek 2018. 01. 01.",
    col_types = "text"
  ) %>%
  clean_names %>%
  select(-megye_kodja) %>%
  rename(
    torzsszam = helyseg_ksh_kod,
    telepules = helyseg_hivatalos_megnevezese,
    telepulesresz = telepulesresz_megnevezese,
    telepulesresz_jelleg = telepulesresz_jelleg_kod,
    irsz = postai_iranyito_szam,
    kulterulet_jellege = a_kulterulet_telepulesi_jellege,
    telepulesresz_tavolsaga_kozponti_belterulettol = a_telepulesresz_tavolsaga_a_kozponti_belterulettol,
    nepszamlalasi_lakonepesseg = a_nepszamlalasi_lakonepesseg,
    lakasok_szama = a_lakasok_szama,
    lakott_egyeb_lakoegysegek_szama = lakott_egyeb_lakoegysegek_szama
  )


# Telepulesreszek tabla tisztitasa

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
  # Gulácsnak van egy kulterulete, aminek mas a torzsszama, mint a falu egyeb
  # reszeinek, raadasul ilyen torzsszam a TSZJ-ben sincs.  Iranyitoszamot nem
  # vesztunk, ennek ugyanaz, mint az egesz faluna.  Dobjuk.
  filter(!(torzsszam == "29444" & telepules == "Gulács"))


# Mentes

usethis::use_data(hnt_telepulesreszek_2018, overwrite = TRUE)
