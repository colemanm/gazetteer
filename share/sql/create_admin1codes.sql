create table admin1codes (
  code varchar(10),
  countrycode char(2),
  admin1_code varchar(10),
  name varchar(200),
  alt_name_english varchar(200),
  geonameid int
);

ALTER TABLE ONLY admin1codes
  ADD CONSTRAINT pk_admin1id PRIMARY KEY (geonameid);
