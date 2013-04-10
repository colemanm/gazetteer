-- Create primary keys in tables

ALTER TABLE ONLY alternatename
	ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (alternatenameid);
ALTER TABLE ONLY geoname
	ADD CONSTRAINT pk_geonameid PRIMARY KEY (geonameid);
ALTER TABLE ONLY countryinfo
	ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);
