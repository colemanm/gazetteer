# GeoNames import to Postgres
This is a guide to getting the raw text formatted [GeoNames](http://www.geonames.org/) data dumps structured and imported into a PostGIS database. It imports all related GeoNames data into tables, creates the proper geometry and indexes, as well as foreign key mappings between the tables.

The [feature codes list](http://download.geonames.org/export/dump/featureCodes_en.txt) is useful for determining what `fcode` features you want to extract from the `geoname` table for use in maps or derivative datasets.

### Download source data

```bash
wget http://download.geonames.org/export/dump/allCountries.zip
wget http://download.geonames.org/export/dump/alternateNames.zip
wget http://download.geonames.org/export/dump/countryInfo.txt
wget http://download.geonames.org/export/dump/iso-languagecodes.txt
```

```bash
unzip allCountries.zip
unzip alternateNames.zip
```

### Create the database
```bash
createdb --username=postgres geonames
createlang --username=postgres plpgsql geonames
psql --username=postgres -d geonames -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
psql --username=postgres -d geonames -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
psql --username=postgres -d geonames -f /usr/share/postgresql/9.1/contrib/postgis_comments.sql
```

### Create tables
_Note: the attribute lengths are subject to change depending on the vintage of the GeoNames dataset. The columns need to be sized appropriately to accommodate what's currently in the dataset, which changes - particularly the `alternatenames` column._

```sql
create table geoname (
	geonameid	int,
	name varchar(200),
	asciiname varchar(200),
	alternatenames varchar(6000),
	latitude float,
	longitude float,
	fclass char(1),
	fcode varchar(10),
	country varchar(2),
	cc2 varchar(60),
	admin1 varchar(20),
	admin2 varchar(80),
	admin3 varchar(20),
	admin4 varchar(20),
	population bigint,
	elevation int,
	gtopo30 int,
	timezone varchar(40),
	moddate date
 );
```

```sql
create table alternatename (
	alternatenameId int,
	geonameid int,
	isoLanguage varchar(7),
	alternateName varchar(200),
	isPreferredName boolean,
	isShortName boolean
 );
```

```sql
create table "countryinfo" (
	iso_alpha2 char(2),
	iso_alpha3 char(3),
	iso_numeric integer,
	fips_code varchar(3),
	name varchar(200),
	capital varchar(200),
	areainsqkm double precision,
	population integer,
	continent varchar(2),
	tld varchar(10),
	currencycode varchar(3),
	currencyname varchar(20),
	phone varchar(20),
	postalcode varchar(100),
	postalcoderegex varchar(200),
  languages varchar(200),
  geonameId int,
	neighbors varchar(50),
	equivfipscode varchar(3)
);
```
#### Insert the data
Run these from the SQL prompt as a permitted user.

```sql
copy geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from 'allCountries.txt' null as '';
```

```sql
copy alternatename  (alternatenameid,geonameid,isolanguage,alternatename,ispreferredname,isshortname) from 'alternateNames.txt' null as '';
```

```sql
copy countryinfo (iso_alpha2,iso_alpha3,iso_numeric,fips_code,name,capital,areainsqkm,population,continent,tld,currencycode,currencyname,phone,postalcode,postalcoderegex,languages,geonameid,neighbors,equivfipscode) from 'countryInfo.txt' null as '';
```

### Add primary key & foreign key constraints

```sql
ALTER TABLE ONLY alternatename
      ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (alternatenameid);
ALTER TABLE ONLY geoname
      ADD CONSTRAINT pk_geonameid PRIMARY KEY (geonameid);
ALTER TABLE ONLY countryinfo
      ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);

ALTER TABLE ONLY countryinfo
      ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);
ALTER TABLE ONLY alternatename
      ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);
```

### Create PostGIS geometry column, insert geometry, and create indexes
```sql
SELECT AddGeometryColumn ('public','geoname','the_geom',4326,'POINT',2);

UPDATE geoname SET the_geom = PointFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);

CREATE INDEX idx_geoname_the_geom ON public.geoname USING gist(the_geom);
```