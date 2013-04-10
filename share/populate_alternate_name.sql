-- Populate alternate names table from file

copy alternatename (
	alternatenameid,
	geonameid,
	isolanguage,
	alternatename,
	ispreferredname,
	isshortname,
	iscolloquial,
	ishistoric
) from '../data/alternateNames.txt' null as '';

ALTER TABLE ONLY alternatename
	ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (alternatenameid);