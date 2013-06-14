create table admin2codes (
  code varchar(50),
  countrycode char(2),
  admin1_code varchar(10),
  name varchar(200),
  alt_name_english varchar(200),
  geonameid int
);

ALTER TABLE ONLY admin2codes
  ADD CONSTRAINT pk_admin2id PRIMARY KEY (geonameid);
