library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(readxl)


# Main table

tsz_2018 <- read_excel(
  path = "data-raw/teruleti_szamjelrendszer_struktura_elemei_2018.xlsx",
  col_names = c("telepules_azonosito_torzsszam", "nev",
                "teruleti_jelzoszam", "jogallas_2005",
                "statisztikai_nagyregio_kodja", "regio_2016",
                "nuts_16", "jaras_kod", "jaras_kozpont_kodja",
                "agglomeracio_kodja",
                "polgarmesteri_hivatal_kozos_onkormanyzati_hivatal_kodja",
                "polgarmesteri_hivatal_kozos_onkormanyzati_hivatal_szekhelyenek_kodja",
                "mezogazdasagi_tajkorzet", "borregio", "borvidek_09",
                "turisztikai_regio", "vilagoroksegi_helyszinek",
                "vilagoroksegi_helyszinek_vedoovezete",
                "nemzeti_parkok",
                "falusi_szallasadas_lehetseges_helyszinei",
                "kedvezmenyezett_telepulesek_kodja",
                "kedvezmenyezett_jarasok_kodja",
                "szabad_vallalkozasi_zonak",
                "teruletfejlesztesi_szempontbol_kiemelt_terseg"),
  skip = 1
)


# Helper table with the main classifications' labels

tsz_2018_megnevezessel <-
  read_excel(
    path = "data-raw/teruleti_szamjelrendszer_struktura_elemei_2018_megnevezesekkel.xlsx",
    col_names = c("telepules_azonosito_torzsszam_telepuleskod", "nev",
                  "teruleti_jelzoszam",
                  "teruleti_jelzoszambol_kepzett_megyekod", "megyenev",
                  "jogallas_2005", "jogallas_2005_megnevezese",
                  "statisztikai_nagyregio_kodja",
                  "statisztikai_nagyregio_neve", "regio_2016_kodja",
                  "regio_neve", "jaras_kod", "jaras_neve"),
    skip = 1
  ) %>%
  # Uniform names
  rename(
    telepules_azonosito_torzsszam = telepules_azonosito_torzsszam_telepuleskod
  ) %>%
  # Drop columns present in both tables
  select(
    -nev, -teruleti_jelzoszam, -jogallas_2005, -statisztikai_nagyregio_kodja,
    -regio_2016_kodja, -jaras_kod
  )


# Joining the tables and simplifying column names

tsz_2018 <- tsz_2018 %>%
  left_join(tsz_2018_megnevezessel, by = "telepules_azonosito_torzsszam") %>%
  select(
    telepules_azonosito_torzsszam, nev, teruleti_jelzoszam,
    teruleti_jelzoszambol_kepzett_megyekod, megyenev, jogallas_2005,
    jogallas_2005_megnevezese, statisztikai_nagyregio_kodja,
    statisztikai_nagyregio_neve, regio_2016, regio_neve, jaras_kod, jaras_neve,
    nuts_16, everything()
  ) %>%
  rename(
    torzsszam = telepules_azonosito_torzsszam,
    telepules = nev,
    megye = teruleti_jelzoszambol_kepzett_megyekod,
    megye_nev = megyenev,
    jogallas_2005_nev = jogallas_2005_megnevezese,
    statisztikai_nagyregio = statisztikai_nagyregio_kodja,
    statisztikai_nagyregio_nev = statisztikai_nagyregio_neve,
    regio = regio_2016,
    regio_nev = regio_neve,
    jaras = jaras_kod,
    jaras_nev = jaras_neve,
    jaras_kozpont = jaras_kozpont_kodja,
    agglomeracio = agglomeracio_kodja,
    polgarmesteri_hivatal_kozos_onkormanyzati_hivatal = polgarmesteri_hivatal_kozos_onkormanyzati_hivatal_kodja,
    polgarmesteri_hivatal_kozos_onkormanyzati_hivatal_szekhely = polgarmesteri_hivatal_kozos_onkormanyzati_hivatal_szekhelyenek_kodja,
    vilagoroksegi_helyszin = vilagoroksegi_helyszinek,
    vilagoroksegi_helyszin_vedoovezete = vilagoroksegi_helyszinek_vedoovezete,
    nemzeti_park = nemzeti_parkok,
    falusi_szallasadas = falusi_szallasadas_lehetseges_helyszinei,
    kedvezmenyezett_telepules = kedvezmenyezett_telepulesek_kodja,
    kedvezmenyezett_jaras = kedvezmenyezett_jarasok_kodja,
    szabad_vallalkozasi_zona = szabad_vallalkozasi_zonak
  )


# A few cosmetic fixes for Budapest

tsz_2018 <- tsz_2018 %>%
  # Budapest's 23 districts are classified under "fovaros". Replace them
  # with Budapest, to make it consistent with other sources.
  mutate(
    megye_nev = if_else(megye == "01", "Budapest", megye_nev)
  ) %>%
  arrange(jaras, jaras_nev) %>%
  fill(jaras_nev) %>%
  arrange(torzsszam)


# Save

usethis::use_data(tsz_2018, overwrite = TRUE)
