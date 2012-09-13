#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'pg'

class GeoNames < Thor

  desc "download", "Download the GeoNames data for a country."
  method_option :country, :aliases => "-c", :desc => "Download a specific country's data"
  method_option :countryinfo, :aliases => "-i", :desc => "Download country info data"
  def download
    country = options[:country]
    if country
      puts "Downloading #{options[:country]}..."
      `wget http://download.geonames.org/export/dump/#{options[:country]}.zip`
      puts "Unzipping..."
      `unzip #{options[:country]}`
      `rm #{options[:country]}.zip`
      `rm readme.txt`
    else
      puts "No country specified... Use '-c FIPSCODE' to download data for a specific country."
    end
  end

  desc "createtables", "Create GeoNames Postgres tables."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  method_option :geoname, :aliases => "-g", :desc => "Create table for GeoNames"
  method_option :altname, :aliases => "-a", :desc => "Create table for alternate names"
  method_option :countryinfo, :aliases => "-c", :desc => "Create table for country info"
  method_option :all, :aliases => "-A", :desc => "Create all GeoNames placeholder tables"
  def createtables
    geoname = options[:geoname]
    alternatenames = options[:altname]
    countryinfo = options[:countryinfo]
    all = options[:all]
    if geoname
  	  puts "Creating \"geoname\" table..."
  	  `psql -d #{options[:dbname]} -c "create table geoname (geonameid int, name varchar(200), asciiname varchar(200), alternatenames varchar(6000), latitude float, longitude float, fclass char(1), fcode varchar(10), country varchar(2), cc2 varchar(60), admin1 varchar(20), admin2 varchar(80), admin3 varchar(20), admin4 varchar(20), population bigint, elevation int, gtopo30 int, timezone varchar(40), moddate date)"`
    elsif alternatenames
  	  puts "Creating \"alternatenames\" table..."
  	  `psql -d #{options[:dbname]} -c "create table alternatename (alternatenameId int, geonameid int, isoLanguage varchar(7), alternateName varchar(200), isPreferredName boolean, isShortName boolean)"`
    elsif countryinfo
  	  puts "Creating \"countryinfo\" table..."
  	  `psql -d #{options[:dbname]} -c "create table countryinfo (iso_alpha2 char(2), iso_alpha3 char(3), iso_numeric integer, fips_code varchar(3), name varchar(200), capital varchar(200), areainsqkm double precision, population integer, continent varchar(2), tld varchar(10), currencycode varchar(3), currencyname varchar(20), phone varchar(20), postalcode varchar(100), postalcoderegex varchar(200), languages varchar(200), geonameId int, neighbors varchar(50), equivfipscode varchar(3))"`
    elsif all
      puts "Creating all GeoNames tables..."
      `psql -d #{options[:dbname]} -c "create table geoname (geonameid int, name varchar(200), asciiname varchar(200), alternatenames varchar(6000), latitude float, longitude float, fclass char(1), fcode varchar(10), country varchar(2), cc2 varchar(60), admin1 varchar(20), admin2 varchar(80), admin3 varchar(20), admin4 varchar(20), population bigint, elevation int, gtopo30 int, timezone varchar(40), moddate date)"`
      `psql -d #{options[:dbname]} -c "create table alternatename (alternatenameId int, geonameid int, isoLanguage varchar(7), alternateName varchar(200), isPreferredName boolean, isShortName boolean)"`
      `psql -d #{options[:dbname]} -c "create table countryinfo (iso_alpha2 char(2), iso_alpha3 char(3), iso_numeric integer, fips_code varchar(3), name varchar(200), capital varchar(200), areainsqkm double precision, population integer, continent varchar(2), tld varchar(10), currencycode varchar(3), currencyname varchar(20), phone varchar(20), postalcode varchar(100), postalcoderegex varchar(200), languages varchar(200), geonameId int, neighbors varchar(50), equivfipscode varchar(3))"`
    end
  end

  desc "import", "Import GeoNames data."
  method_option :dbname, :aliases => "-d", :desc => "Database name"
  method_option :file, :aliases => "-f", :desc => "GeoNames text file to import, full path"
  def import
    puts "Importing names from #{options[:file]}..."
    `psql -d #{options[:dbname]} -c "copy geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from '#{options[:file]}' null as ''"`
  end
  
  # UNFINISHED
  desc "query", "Poll your local GeoNames database."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  method_option :list, :aliases => "-l", :desc => "List countries"
  def query
    conn = PGconn.open(:dbname => options[:dbname])
    res = conn.exec('SELECT DISTINCT country FROM geoname')
    res.each do |row|
      row.each do |column|
        puts column
      end
    end
  end
  
  desc "country", "Extract a chunk of a GeoNames database by country and insert into a new table."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  method_option :src, :aliases => "-s", :desc => "Source table name", :required => true
  method_option :dst, :aliases => "-t", :desc => "Destination table name", :required => true
  method_option :country, :aliases => "-c", :desc => "Country code you want to extract and insert.", :required => true
  def country
    `psql -d #{options[:dbname]} -c "CREATE TABLE #{options[:dst]} AS SELECT * FROM #{options[:src]} WHERE country = '#{options[:country]}'"`
  end
    
end

GeoNames.start