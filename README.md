# teroszt – An R package with data for Hungarian administrative and statistical divisions

<!-- badges: start -->

[![Travis build status](https://travis-ci.com/svraka/teroszt.svg?branch=master)](https://travis-ci.com/svraka/teroszt) [![CRAN](http://www.r-pkg.org/badges/version/teroszt)](https://cran.r-project.org/package=teroszt)

<!-- badges: end -->

This package provides data for Hungarian statistical and administrative divisions and crosswalks among them.

  * The Hungarian Central Statistical Office's (HCSO) [territorial code system](https://www.ksh.hu/tszJ_eng_menu) ([*Területi számjelrendszer*](http://www.ksh.hu/teruleti_szamjel_menu))
  * [Detailed Gazetteer](http://www.ksh.hu/apps/hntr.main?p_lang=EN) ([*Helységnévtár*](http://www.ksh.hu/apps/hntr.main))
  * Tables linking HCSO's settlement identification numbers to [postal codes](https://www.posta.hu/szolgaltatasok/iranyitoszam-kereso)
  * [Territorial codes used by the National Tax and Customs Administration](http://www.nav.gov.hu/nav/adatbazisok/adatbleker/afaalanyok/afaalanytaj.html) (NTCA)
  * Administrative boundaries based on [OpenStreetMap data](https://data2.openstreetmap.hu/hatarok/)

The name comes from shortening *ter*ületi *oszt*ályozások, meaning territorial classifications in Hungarian.

## Installation

This package is not (yet) on CRAN. The latest development version can be installed from GitHub:

``` r
# install.packages("devtools")
remotes::install_github("svraka/teroszt")
```
