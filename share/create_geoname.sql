-- Create placeholder GeoNames table

create table geoname (
	geonameid	int,
	name varchar(200),
	asciiname varchar(200),
	alternatenames varchar(8000),
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
