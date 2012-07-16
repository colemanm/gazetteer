#!/usr/bin/env ruby

require 'rubygems'
require 'thor'

class GeoNames < Thor

  desc "download", "Download the GeoNames data for a country."
  method_option :country, :aliases => "-c", :desc => "Download a specific country's data"
  def download
    puts "Downloading #{options[:country]}..."
    `wget http://download.geonames.org/export/dump/#{options[:country]}.zip`
    puts "Unzipping..."
    `unzip #{options[:country]}`
    `rm readme.txt`
  end

  desc "createtables", "Create GeoNames Postgres tables."
  method_option :dbname, :aliases => "-d", :desc => "Database name"
  method_option :geoname, :aliases => "-g", :desc => "Create table for GeoNames"
  method_option :altname, :aliases => "-a", :desc => "Create table for alternate names"
  method_option :countryinfo, :aliases => "-c", :desc => "Create table for country info"
  def createtables
  	puts "Creating \"geoname\" table..."
  	`psql -d #{options[:dbname]} -c "create table geoname (geonameid int, name varchar(200), asciiname varchar(200), alternatenames varchar(6000), latitude float, longitude float, fclass char(1), fcode varchar(10), country varchar(2), cc2 varchar(60), admin1 varchar(20), admin2 varchar(80), admin3 varchar(20), admin4 varchar(20), population bigint, elevation int, gtopo30 int, timezone varchar(40), moddate date)"`
  	puts "Creating \"alternatenames\" table..."
  	`psql -d #{options[:dbname]} -c "create table alternatename (alternatenameId int, geonameid int, isoLanguage varchar(7), alternateName varchar(200), isPreferredName boolean, isShortName boolean)"`
  	puts "Creating \"countryinfo\" table..."
  	`psql -d #{options[:dbname]} -c "create table countryinfo (iso_alpha2 char(2), iso_alpha3 char(3), iso_numeric integer, fips_code varchar(3), name varchar(200), capital varchar(200), areainsqkm double precision, population integer, continent varchar(2), tld varchar(10), currencycode varchar(3), currencyname varchar(20), phone varchar(20), postalcode varchar(100), postalcoderegex varchar(200), languages varchar(200), geonameId int, neighbors varchar(50), equivfipscode varchar(3))"`
  end

end

GeoNames.start