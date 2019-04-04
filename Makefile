.PHONY: all rdas document

scripts = $(wildcard data-raw/*.R)
rdas = $(subst data-raw/, data/, $(addsuffix .rda, $(basename $(scripts))))

all: rdas document

rdas: $(rdas)

data/tsz_2018.rda: data-raw/tsz_2018.R data-raw/teruleti_szamjelrendszer_struktura_elemei_2018.xlsx data-raw/teruleti_szamjelrendszer_struktura_elemei_2018_megnevezesekkel.xlsx
	Rscript -e 'source("$<", encoding = "UTF-8")'

document:
	Rscript -e 'devtools::document()'
