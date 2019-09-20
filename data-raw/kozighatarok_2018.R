library(dplyr)
library(sf)
library(stringr)
library(tibble)

# Read OSM data downloaded from <https://data2.openstreetmap.hu/hatarok/>.

tmp <- tempdir()

unzip("data-raw/kozighatarok.zip", exdir = tmp)

# Read all admin levels, including level 10 (wards) which have no
# pairs in the territorial code system.

kozighatarok <- list.files(file.path(tmp, "kozighatarok"),
                           pattern = "admin\\d+\\.shp",
                           full.names = TRUE) %>%
  lapply(st_read) %>%
  do.call(rbind, .) %>%
  remove_rownames() %>%
  # Convert to latlong, same what Eurostat uses
  st_transform(crs = "+proj=longlat +datum=WGS84 +no_defs") %>%
  mutate_if(is.factor, as.character) %>%
  mutate(ADMIN_LEVE = str_pad(ADMIN_LEVE, width = 2, pad = "0"))

# Prepare OSM data

# Clean county and district names
kozighatarok <- kozighatarok %>%
  mutate(NAME = str_remove(NAME, regex("\\ (megye|járás)$", ignore_case = TRUE)))

# Convert Budapest district names to same structure used by HCSO and
# change `ADMIN_LEVE` to district (járás) level for Budapest
# districts.

convert_kerulet <- function(x) {
  string_roman <- x %>%
    str_extract(".+\\.\\ kerület$") %>%
    str_remove("\\.\\ kerület$")

  arabic <- string_roman %>% as.roman %>% as.integer
  padded <- str_pad(arabic, width = 2, pad = "0")
  string <- str_c("Budapest ", padded, ". ker.")

  string
}

kozighatarok <- kozighatarok %>%
  mutate(
    NAME       = if_else(ADMIN_LEVE == "09", convert_kerulet(NAME), NAME),
    ADMIN_LEVE = if_else(ADMIN_LEVE == "09", "07", ADMIN_LEVE)
  )

# Budapest districts are also settlements with their own HCSO IDs
# (`torzsszam`). We duplicate these observations.

kozighatarok_kieg_district <- kozighatarok %>%
    filter(str_detect(NAME, "Budapest\\ \\d+\\.\\ ker\\.")) %>%
    mutate(ADMIN_LEVE = "08")

kozighatarok <- rbind(kozighatarok, kozighatarok_kieg_district)

# OSM has old data which doesn't correspond to current Eurostat
# classifiactions. With NUTS 2016 Central Hungary region was split
# into Budapest, and Pest county.

kozighatarok <- kozighatarok %>%
    filter(!(NAME == "Közép-Magyarország" & ADMIN_LEVE == "05"))

kozighatarok_kieg_region <- kozighatarok %>%
    filter(NAME %in% c("Budapest", "Pest"), ADMIN_LEVE == "06") %>%
    mutate(ADMIN_LEVE = "05")

kozighatarok <- rbind(kozighatarok, kozighatarok_kieg_region)
    
# Prepare HCSO data

load("data/tsz_2018.rda")

# Add `ADMIN_LEVE` codes

tsz_2018 <- tsz_2018 %>%
  rename(tel_nev = telepules)

tsz_2018_levels <- bind_rows(
    tsz_2018 %>% distinct(regio_nev, regio) %>% mutate(ADMIN_LEVE = "05"),
    tsz_2018 %>% distinct(megye_nev, megye) %>% mutate(ADMIN_LEVE = "06"),
    tsz_2018 %>% distinct(jaras_nev, jaras) %>% mutate(ADMIN_LEVE = "07"),
    tsz_2018 %>% distinct(tel_nev, torzsszam) %>% mutate(ADMIN_LEVE = "08")
  ) %>%
  mutate(NAME = coalesce(!!! select(., ends_with("_nev")))) %>%
  select(-ends_with("_nev")) %>%
  mutate(CODE = coalesce(!!! select(., -ADMIN_LEVE, -NAME))) %>%
  select(., ADMIN_LEVE, NAME, CODE)

# Join maps with HCSO IDs

kozighatarok_2018 <- kozighatarok %>%
  left_join(tsz_2018_levels, by = c("NAME", "ADMIN_LEVE")) %>%
  arrange(ADMIN_LEVE, CODE)

# Saving

usethis::use_data(kozighatarok_2018, overwrite = TRUE, compress = "xz")
