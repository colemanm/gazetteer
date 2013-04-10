-- Populate countryinfo table from file

copy countryinfo (
	iso_alpha2,
	iso_alpha3,
	iso_numeric,
	fips_code,
	name,
	capital,
	areainsqkm,
	population,
	continent,
	tld,
	currencycode,
	currencyname,
	phone,
	postalcode,
	postalcoderegex,
	languages,
	geonameid,
	neighbors,
	equivfipscode
) from '../data/countryinfo.txt' null as '';

ALTER TABLE ONLY countryinfo
	ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);