#' @import sf
#' @importFrom tibble tibble
#' @keywords internal
"_PACKAGE"

#' 2018 edition of the territorial code system
#'
#' A dataset with the 2018 edition of the Hungarian Central
#' Statistical Office's territorial code system (\sQuote{területi
#' számjelrendszer}).
#'
#' @format A tibble with 3,200 rows, for each settlement that has an ID
#'   number (\sQuote{településazonosító törzsszám}) with codes for the
#'   classifications in the territorial code system, along with labels
#'   for the main classifications. For a detailed explanation of the
#'   variables see HCSO's documentation.
#'
#' @source The present content was prepared using the territorial
#'   classification system of the Hungarian Central Statistical Office
#'   (\url{https://www.ksh.hu/tszJ_eng_menu}). What is included in
#'   this package is the intellectual product solely of this package's
#'   authors. Downloaded at 4 April 2019.
"tsz_2018"

#' Settlement parts from 2018 edition of the Detailed Gazetteer
#'
#' A dataset with settlement parts' information from the 2018 edition
#' of the Hungarian Central Statistical Office's Detailed Gazetteer.
#'
#' @format A tibble with 13,558 rows, containing all settlements and
#'   settlement parts in the Detailed Gazetteer, with the following
#'   variables:
#'
#' \describe{
#'   \item{torzsszam}{The settlement's HCSO ID number
#'     (\sQuote{településazonosító törzsszám})}
#'   \item{telepules}{Name of the settlement}
#'   \item{telepulesresz}{Name of the settlement part}
#'   \item{telepulesresz_jelleg}{Type of the settlement part:
#'     \sQuote{központi belterület} (central built-up area),
#'     \sQuote{belterület} (built-up area), \sQuote{külterület}
#'     (outside of built-up area)}
#'   \item{irsz}{Postal code (incomplete, postal codes based on street
#'     address level classification -- used in the largest cities --
#'     are missing)}
#'   \item{kulterulet_jellege}{Type of non--built-up area, based on HCSO's
#'     methodology}
#'   \item{telepulesresz_tavolsaga_kozponti_belterulettol}{Distance of
#'     the settlement part from the settlement's central built-up area (km)}
#'   \item{nepszamlalasi_lakonepesseg}{Resident population at the time
#'     of the last census}
#'   \item{lakasok_szama}{Number of dwellings}
#'   \item{lakott_egyeb_lakoegysegek_szama}{Number of occupied other
#'     housing units}
#' }
#'
#' @source The present content was prepared using the Detailed
#'   Gazetteer of the Hungarian Central Statistical Office
#'   (\url{http://www.ksh.hu/apps/hntr.main?p_lang=EN}). What is
#'   included in this package is the intellectual product solely of
#'   this package's authors. Downloaded at 5 April 2019.
"hnt_telepulesreszek_2018"

#' Postal codes and settlements (2018)
#'
#' A crosswalk table connecting Hungarian Postal Service's postal
#' codes (\sQuote{\emph{ir}ányító\emph{sz}ám}) and the HCSO's
#' settlement IDs.
#'
#' @format A tibble with 4,395 rows, which gives a crosswalk between
#'   all the valid postal codes in the Hungarian Postal Service's
#'   database, and settlement IDs for all settlements that share a
#'   postal code.
#'
#' \describe{
#'   \item{torzsszam}{The settlement's HCSO ID number
#'     (\sQuote{településazonosító törzsszám})}
#'   \item{telepules}{Name of the settlement}
#'   \item{irsz}{Postal code}
#'   \item{torzsszam_fo_telepules}{Settlement ID number for the primary
#'     settlement using a postal code. As settlements
#'     can share postal codes, a raw crosswalk between \code{irsz_2018}
#'     and \link{tsz_2018} is ambiguous. Most overlaps happen in
#'     parts of settlements with low-populations in non-central, or
#'     even non--build-up areas. This column contains a unique settlement ID
#'     for each postal code belonging to settlement most likely to be
#'     representative of that postal code. Classification is
#'     based on borough types (preferring central over, non-central)
#'     and the boroughs' population sizes.}
#' }
#'
#' @details Postal codes include regular codes (used in towns and
#'   villages), street address based codes (used in cities), and codes
#'   for post offices (including mobile offices).
#'
#' Note that postal codes can cross settlement boundaries, therefore
#' using \code{torzsszam_fo_telepules} can lead to some
#' misclassification.
#'
#' @source The present content was prepared using the Detailed
#'   Gazetteer of the Hungarian Central Statistical Office
#'   (\url{http://www.ksh.hu/apps/hntr.main?p_lang=EN}). What is
#'   included in this package is the intellectual product solely of
#'   this package's authors. Downloaded at 5 April 2019.
#'
#' The source of the postal codes is Hungarian Postal Service's
#' (\sQuote{Magyar Posta Zrt.}) website:
#'
#' \itemize{
#'   \item{
#'     \url{https://www.posta.hu/szolgaltatasok/iranyitoszam-kereso},
#'     downloaded at 5 April 2019)}
#'   \item{
#'     \url{https://www.posta.hu/static/internet/download/Allando_postai_szolgaltatohelyek.xlsx},
#'     downloaded at 12 August 2020}
#' }
"irsz_2018"

#' National Tax and Customs Administration's directorates
#'
#' A territorial classification used by the National Tax and Customs
#' Administration (\sQuote{Nemzeti Adó- és Vámhivatal}) to identify
#' directorates, and a crosswalk between the directorates' counties
#' (\sQuote{megye}) and districts (\sQuote{járás}) from the
#' territorial code system.
#'
#' @format A tibble with 199 rows, which connects every district
#'   (\sQuote{járás}) to their respective tax directorate. A fictional
#'   \code{999} code is used for directorates of Large Taxpayers,
#'   which opearate on a non-territorial basis.
#'
#' \describe{
#'   \item{nav_ig_nev}{Name of the directorate}
#'   \item{nav_ig_tarsas}{Code of the directorate for corporate
#'     taxpayers}
#'   \item{nav_ig_egyeni}{Code of the directorate for sole propriator
#'     taxpayers}
#'   \item{megye}{County code, see \link{tsz_2018}}
#'   \item{jaras}{District code, see \link{tsz_2018}}
#' }
#'
#' @details The directorates' codes correspond the last two digits of
#'   the tax IDs.
#'
#' @source
#' \url{http://www.nav.gov.hu/nav/adatbazisok/adatbleker/afaalanyok/afaalany_taj.html}.
#' Downloaded at 10 April 2019.
"nav_igazgatosagi_kodok"

#' Geospatial data of Hungarian administrative divisions from OpenStreetMap
#'
#' A data frame with geographic boundaries for all Hungarian administrative
#' divisions based on OpenStreetMap data. Adopted for compatibility with HCSO
#' territorial code system.
#'
#' @format A Simple Features data frame.
#'
#' \describe{
#'   \item{NAME}{Name of the administrative division.}
#'   \item{ADMIN_LEVE}{OpenStreetMap \code{admin_level} values, see
#'     \url{https://wiki.openstreetmap.org/wiki/Tag:boundary\%3Dadministrative#10_admin_level_values_for_specific_countries}.}
#'   \item{ADMIN_NAME}{Label for \code{ADMIN_LEVE}.}
#'   \item{CODE}{IDs used by HCSO for administrative divisions.}
#'   \item{geometry}{Geospatial information.}
#' }
#'
#' @source OpenStreetMap \url{https://data2.openstreetmap.hu/hatarok/}, licenced
#'   under CC BY-SA \url{https://www.openstreetmap.org/copyright} ©
#'   OpenStreetMap contributors. Downloaded on 13th September 2019.
"kozighatarok_2018"
