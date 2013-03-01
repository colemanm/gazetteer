# Insert GeoNames data

copy geoname (
	geonameid,
	name,
	asciiname,
	alternatenames,
	latitude,
	longitude,
	fclass,
	fcode,
	country,
	cc2,
	admin1,
	admin2,
	admin3,
	admin4,
	population,
	elevation,
	gtopo30,
	timezone,
	moddate
) from 'allCountries.txt' null as '';

# Set primary key
ALTER TABLE ONLY geoname
	ADD CONSTRAINT pk_geonameid PRIMARY KEY (geonameid);

# Add geometry column
SELECT AddGeometryColumn ('public','geoname','the_geom',4326,'POINT',2);

# Calculate and set geometry
UPDATE geoname SET the_geom = ST_PointFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);

# Index geometry
CREATE INDEX idx_geoname_the_geom ON public.geoname USING gist(the_geom);