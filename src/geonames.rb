#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'pg'

class Gazetteer < Thor

  desc "download", "Download the GeoNames data for a country."
  method_option :country, :aliases => "-c", :desc => "Download a specific country's data"
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

  desc "createtables", "Create GeoNames PostGIS tables."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  def createtables
    geoname = options[:geoname]
    alternatenames = options[:altname]
    countryinfo = options[:countryinfo]

    puts "Creating \"geoname\" table..."
    `psql -d #{options[:dbname]} -f "#{File.join(File.dirname(__FILE__), '..', 'share', 'create_geoname.sql')}"`
    puts "Table \"geoname\" created."

    puts "Creating \"alternatenames\" table..."
    `psql -d #{options[:dbname]} -f "#{File.join(File.dirname(__FILE__), '..', 'share', 'create_alternate_name.sql')}"`
    puts "Table \"alternatenames\" created."
    
    puts "Creating \"countryinfo\" table..."
    `psql -d #{options[:dbname]} -f "#{File.join(File.dirname(__FILE__), '..', 'share', 'create_country_info.sql')}"`
    puts "Table \"countryinfo\" created."

    puts "Setting primary keys..."
    `psql -d #{options[:dbname]} -f "#{File.join(File.dirname(__FILE__), '..', 'share', 'create_primary_keys.sql')}"`
    puts "Primary keys created."

    puts "Setting foreign keys..."
    `psql -d #{options[:dbname]} -f "#{File.join(File.dirname(__FILE__), '..', 'share', 'create_foreign_keys.sql')}"`
    puts "Foreign keys created."
  end

  desc "altnames", "Import alternate names data table."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  method_option :file, :aliases => "-f", :desc => "Alternate names file, full path", :required => true
  def altnames
    `psql -d #{options[:dbname]} -c "copy alternatename (alternatenameid,geonameid,isolanguage,alternatename,ispreferredname,isshortname,iscolloquial,ishistoric) from '#{options[:file]}' null as ''"`
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
  method_option :user, :aliases => "-u", :desc => "Database user name", :required => true
  method_option :src, :aliases => "-s", :desc => "Source table name", :required => true
  method_option :dst, :aliases => "-t", :desc => "Destination table name", :required => true
  method_option :country, :aliases => "-c", :desc => "Country code you want to extract and insert.", :required => true
  def country
    `psql -U #{options[:user]} -d #{options[:dbname]} -c "CREATE TABLE #{options[:dst]} AS SELECT * FROM #{options[:src]} WHERE country = '#{options[:country]}'"`
  end
  
  desc "list", "List countries available in a GeoNames database."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  method_option :user, :aliases => "-u", :desc => "Database user name", :required => true
  method_option :table, :aliases => "-t", :desc => "Table containing GeoNames records", :required => true
  def list
    `psql -U #{options[:user]} -d #{options[:dbname]} -c "SELECT DISTINCT country FROM #{options[:table]} ORDER BY country ASC"`
  end
    
end

Gazetteer.start