#' @importFrom tibble tibble
NULL

#' A területi számjelrendszer (TSZJ) 2018-as kiadása
#'
#' Ez a tábla a KSH területi számjelrendszerének (TSZJ) 2018-as kiadását
#' tartalmazza.
#'
#' @format
#' Egy data frame 3200 sorral, amely minden településazonosító törzsszámmal
#' rendelkező településről tartalmazza a területi számjelrendszerkategóriái
#' szerinti besorolását a kategóriák kódjával, és a fontosabb csoportosításokról
#' a kategóriák megnevezésével.  A változók tartalmának részletes leírása és a
#' megnevezés nélküli kategóriák nevei megtalálhatóak a KSH módszertani
#' dokumentációjában.
#'
#' @source
#' A jelen tartalom a Központi Statisztikai Hivatal területi számjelrendszere
#' (\url{http://www.ksh.hu/teruleti_szamjel_menu}) 2018-as kiadásának
#' felhasználásával készült.  A csomagban foglaltak kizárólag Svraka András,
#' mint szerző szellemi termékei.  A letöltés dátuma 2019. április 4.
"tsz_2018"

#' Településrészek a Helységnévtár 2018-as kiadásából
#'
#' Ez a tábla a KSH Helységnévtárának 2018-as kiadásából tartalmazza a
#' településrészeket.
#'
#' @format Egy data frame 13 558 sorral, amely a Helységnévtárban szereplő
#' összes település településrészével az alábbi változókkal:
#'
#' \describe{
#'   \item{torzsszam}{A település KSH-s településazonosító törzsszáma}
#'   \item{telepules}{Település neve}
#'   \item{telepulesresz}{Településrész neve}
#'   \item{telepulesresz_jelleg}{Településrész jellege (központi belterület,
#'     belterület, külterület)}
#'   \item{irsz}{Irányítószám (nem teljes körű, hiányoznak az utcajegyzék
#'     alapján meghatározott irányítószámok)}
#'   \item{kulterulet_jellege}{Külterület jellege a KSH módszertana szerint}
#'   \item{telepulesresz_tavolsaga_kozponti_belterulettol}{A településrész
#'     távolsága a központi belterülettől (km)}
#'   \item{nepszamlalasi_lakonepesseg}{A népszámlálási lakónépesség (fő)}
#'   \item{lakasok_szama}{A lakások száma (db)}
#'   \item{lakott_egyeb_lakoegysegek_szama}{Lakott egyéb lakóegységek száma
#'     (db)}
#' }
#'
#' @source
#' A jelen tartalom a Központi Statisztikai Hivatal Helységnévtára
#' (\url{http://www.ksh.hu/apps/hntr.main}) 2018-as kiadásának felhasználásával
#' készült.  A csomagban foglaltak kizárólag Svraka András, mint szerző szellemi
#' termékei.  A letöltés dátuma 2019. április 5.
"hnt_telepulesreszek_2018"

#' Irányítószámok és települések (2018)
#'
#' A Magyar Posta nyilvántartása szerinti összes irányítószám, a kapcsolódó
#' település neve a KSH helységnévtárából hozzákapcsolva a településazonosító
#' törzsszámokat.
#'
#' @format
#' Egy data frame 3859 sorral, amely minden, a Helységnévtárban és a Posta
#' nyilvántartásában szereplő irányítószámhoz megadja a települést.
#'
#' \describe{
#'   \item{torzsszam}{A település KSH-s településazonosító törzsszáma}
#'   \item{telepules}{Település neve}
#'   \item{irsz}{Irányítószám}
#' }
#'
#' @source
#' A jelen tartalom a Központi Statisztikai Hivatal Helységnévtára
#' (\url{http://www.ksh.hu/apps/hntr.main}) 2018-as kiadásának felhasználásával
#' készült.  A csomagban foglaltak kizárólag Svraka András, mint szerző szellemi
#' termékei.  A letöltés dátuma 2019. április 4.
#'
#' Az irányítószámok forrása a Magyar Posta Zrt. honlapján közzétett
#' \dQuote{Magyarországi postai irányítószámok}
#' (\url{https://www.posta.hu/szolgaltatasok/iranyitoszam-kereso}).  A letöltés
#' dátuma 2019. április 5.
"irsz_2018"

#' NAV igazgatósági kódok
#'
#' A Nemzeti Adó- és Vámhivatal által használt területi igazgatósági kódok és a
#' hozzájuk kapcsolódó megye- és járáskódok a területi számrendszerből.  Ezek az
#' igazgatósági kódok az adószám utolsó két számjegyei is.
#'
#' @format
#' Egy data frame 199 sorral, amely minden járáshoz megadja az illetékes NAV
#' igazgatóság kódját.  A 999-es, fiktív járáshoz lett sorolva a két kiemelt
#' igazgatóság.
#'
#' \describe{
#'   \item{nav_ig_nev}{Az igazgatóság neve}
#'   \item{nav_ig_tarsas}{Igazgatóság kódja, társas adóalany esetén}
#'   \item{nav_ig_egyeni}{Igazgatóság kódja, egyéni adóalany esetén}
#'   \item{megye}{Megye kódja (ld. TSZJ)}
#'   \item{jaras}{Járás kódja (ld. TSZJ)}
#' }
#'
#' @source
#' (\url{http://www.nav.gov.hu/nav/adatbazisok/adatbleker/afaalanyok/afaalany_taj.html}).
#' A hozzáférés dátuma 2019. április 10.
"nav_igazgatosagi_kodok"
