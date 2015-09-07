PREFIX				?= ~/local/gazetteer
BIN_PREFIX			?= $(PREFIX)/bin
SHARE_PREFIX		?= $(PREFIX)/share
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
	cities

# Download cities only
cities: \
	data/cities15000.txt \
	data/cities5000.txt \
	data/cities1000.txt

# Zips
data/allcountries.zip:
	curl -s -o data/allcountries.zip "http://download.geonames.org/export/dump/allCountries.zip"

data/alternatenames.zip:
	curl -s -o data/alternatenames.zip "http://download.geonames.org/export/dump/alternateNames.zip"

data/allcountries.txt: data/allcountries.zip
	unzip -d data/ data/allcountries.zip
	touch data/allcountries.txt
	rm data/allcountries.zip

data/alternatenames.txt: data/alternatenames.zip
	unzip -d data/ data/alternatenames.zip
	touch data/alternatenames.txt
	touch data/iso-languagecodes.txt
	rm data/alternatenames.zip

# Cities
data/cities15000.zip:
	curl -s -o data/cities15000.zip "http://download.geonames.org/export/dump/cities15000.zip"

data/cities5000.zip:
	curl -s -o data/cities5000.zip "http://download.geonames.org/export/dump/cities5000.zip"

data/cities1000.zip:
	curl -s -o data/cities1000.zip "http://download.geonames.org/export/dump/cities1000.zip"

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
