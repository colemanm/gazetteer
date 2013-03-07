PREFIX					?= ~/local/gazetteer
BIN_PREFIX			?= $(PREFIX)/bin
SHARE_PREFIX		?= $(PREFIX)/share
CONFIG_PREFIX		?= ~

BIN_SCRIPTS			:= $(wildcard src/*)
SHARE_SCRIPTS		:= $(wildcard share/*)

install:
	mkdir -p $(BIN_PREFIX)
	mkdir -p $(SHARE_PREFIX)

	cp $(BIN_SCRIPTS) $(BIN_PREFIX)
	cp $(SHARE_SCRIPTS) $(SHARE_PREFIX)

	for file in $(BIN_PREFIX)/* ; do mv $$file `echo $$file | cut -d'.' -f1` ; done

	chmod +x $(BIN_PREFIX)/*

	@echo "Make sure $(BIN_PREFIX) is in your PATH"

# Download all GeoNames data
data: \
	data/allcountries.txt \
	data/alternatenames.txt \
	metadata \
	cities

# Download cities only
cities: \
	data/cities15000.txt \
	data/cities5000.txt \
	data/cities1000.txt

# Zips

data/allcountries.zip:
	curl -o data/allcountries.zip "http://download.geonames.org/export/dump/allCountries.zip"

data/alternatenames.zip:
	curl -o data/alternatenames.zip "http://download.geonames.org/export/dump/alternateNames.zip"

data/allcountries.txt: data/allcountries.zip
	unzip -d data/ data/allcountries.zip
	touch data/allcountries.txt
	rm data/allcountries.zip

data/alternatenames.txt: data/alternatenames.zip
	unzip -d data/ data/alternateNames.zip
	touch data/alternateNames.txt
	touch data/iso-languagecodes.txt
	rm data/alternatenames.zip

# Metadata

metadata: \
	data/countryinfo.txt \
	data/featurecodes.txt \
	data/admin1codes.txt \
	data/admin2codes.txt

data/countryinfo.txt:
	curl -o data/countryinfo.txt http://download.geonames.org/export/dump/countryInfo.txt
data/featurecodes.txt:
	curl -o data/featurecodes.txt "http://download.geonames.org/export/dump/featureCodes_en.txt"
data/admin1codes.txt:
	curl -o data/admin1codes.txt "http://download.geonames.org/export/dump/admin1CodesASCII.txt"
data/admin2codes.txt:
	curl -o data/admin2codes.txt "http://download.geonames.org/export/dump/admin2Codes.txt"

# Cities


data/cities15000.zip:
	curl -o data/cities15000.zip "http://download.geonames.org/export/dump/cities15000.zip"

data/cities5000.zip:
	curl -o data/cities5000.zip "http://download.geonames.org/export/dump/cities5000.zip"

data/cities1000.zip:
	curl -o data/cities1000.zip "http://download.geonames.org/export/dump/cities1000.zip"

data/cities15000.txt: data/cities15000.zip
	unzip -d data/ data/cities15000.zip
	touch data/cities15000.txt
	rm data/cities15000.zip

data/cities5000.txt: data/cities5000.zip
	unzip -d data/ data/cities5000.zip
	touch data/cities5000.txt
	rm data/cities5000.zip

data/cities1000.txt: data/cities1000.zip
	unzip -d data/ data/cities1000.zip
	touch data/cities1000.txt
	rm data/cities1000.zip

clean:
	rm data/*
	@echo "Source data cleaned."

uninstall:
	rm -rf $(BIN_PREFIX)
	rm -rf $(PREFIX)

.PHONY: install uninstall