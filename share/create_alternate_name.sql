-- Create alternate names table

create table alternatename (
	alternatenameId int,
	geonameid int,
	isoLanguage varchar(7),
	alternateName varchar(200),
	isPreferredName boolean,
	isShortName boolean,
	isColloquial boolean,
	isHistoric boolean
 );