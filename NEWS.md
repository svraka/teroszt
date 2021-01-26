# teroszt 0.4.0 (development version)

## New data

  * Add settlement ID for primary settlement of a postal code in `irsz_2018`. As
    settlements can share postal codes, a raw crosswalk between `irsz_2018` and
    `tsz_2018` is ambiguous. Most overlaps happen in parts of settlements with
    low-populations in non-central, or even non--build-up areas. This column
    contains a unique settlement ID for each postal code belonging to settlement
    most likely to be representative of that postal code. Classification is
    based on borough types (preferring central over, non-central) and the
    boroughs' population sizes (#4).
  * Add postal codes based on post office addresses to `irsz_2018`. This extends
    the number of postal codes covered in `irsz_2018` (#5).
  * Add `get_irsz_tsz_crosswalk()`, a helper function to transform `irsz_2018`
    (and similar crosswalk tables in the future) into an unambiguous postal code
    to settlement ID crosswalk.

## Miscellaneous

  * Set factor levels on code label types columns in `tsz_2018` and
    `nav_igazgatosagi_kodok` (e.g. `megye_nev` became a factor with levels
    ordered by values of `megye`) (#7).

## Documentation

  * Translated all documentation to English in preparation for a future CRAN
    release.
  * Various documentation fixes.

## Internals

  * Set up GitHub Actions.
  * Removed build dependency on **janitor**. We used it only for the
    `clean_names()` function to automatically clean column names in Excel files.
    However, its results can change, therefore we explicitly name all columns
    while reading Excel-files.

# teroszt 0.3.0

## New data

  * Add `kozighatarok_2018`, a geospatial data frame with Hungarian
    administrative boundaries based on [OpenStreetMap
    data](https://data2.openstreetmap.hu/hatarok/).

# teroszt 0.2.1

## New data

  * Add a new `csak_kulterulet` column to `irsz_2018`: Some settlements share
    postal codes. This column flags if a postal code within a settlement only
    covers area outside a built-up area (*külterület*). This is intended to help
    classifying postal codes into administrative divisions in case the postal
    code is ambiguous.

# teroszt 0.2.0

## New data

  * `nav_igazgatosagi_kodok`: Territorial classifications used by the National
    Tax and Customs Office, and their crosswalks to counties (*megye*) and
    districts (*járás*).

## Miscellaneous

  * Documentation fixes

# teroszt 0.1.0: Data for 2018

First release, with the following tables

  * 2018 territorial code system (`tsz_2018`).
  * 2018 settlements and settlement parts based on the Detailed Gazetteer
    (`hnt_telepulesreszek_2018`).
  * Crosswalk table between postal codes and settlement IDs in the territorial
    code system (*településazonosító törzsszámok*) based on the 2018 Gazetteer
    (`irsz_2018`).
