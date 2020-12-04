.PHONY: all rdas document

scripts = $(wildcard data-raw/*.R)
rdas = $(subst data-raw/, data/, $(addsuffix .rda, $(basename $(scripts))))

all: rdas document

rdas: $(rdas)

data/tsz_2018.rda: data-raw/tsz_2018.R data-raw/teruleti_szamjelrendszer_struktura_elemei_2018.xlsx data-raw/teruleti_szamjelrendszer_struktura_elemei_2018_megnevezesekkel.xlsx
	Rscript -e 'source("$<", encoding = "UTF-8")'

data/hnt_telepulesreszek_2018.rda: data-raw/hnt_telepulesreszek_2018.R data-raw/hnt_2018.xls data-raw/hnt_telepulesresz_jelleg.csv
	Rscript -e 'source("$<", encoding = "UTF-8")'

data/irsz_2018.rda: data-raw/irsz_2018.R data-raw/iranyitoszam_2019-01-15.xlsx data-raw/hnt_2018.xls data/hnt_telepulesreszek_2018.rda data/tsz_2018.rda
	Rscript -e 'source("$<", encoding = "UTF-8")'

data/nav_igazgatosagi_kodok.rda: data-raw/nav_igazgatosagi_kodok.R data-raw/nav_igazgatosagi_kodok.csv
	Rscript -e 'source("$<", encoding = "UTF-8")'

data/kozighatarok_2018.rda: data-raw/kozighatarok_2018.R data-raw/kozighatarok.zip data/tsz_2018.rda
	Rscript -e 'source("$<", encoding = "UTF-8")'

document:
	Rscript -e 'devtools::document()'
