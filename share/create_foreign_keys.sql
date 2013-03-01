-- Create foreign keys in country info and alternate names

ALTER TABLE ONLY countryinfo
	ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);
ALTER TABLE ONLY alternatename
	ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);