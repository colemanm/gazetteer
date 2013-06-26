#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'json'
require 'csv'
require 'yaml'
require 'pg'
require 'sequel'

class Gazetteer < Thor

  SHARE_PATH = "share"
  DATA_PATH = "data"
  METADATA_PATH = File.expand_path(File.join(SHARE_PATH, "metadata"))
  SQL_PATH = File.expand_path(File.join(SHARE_PATH, "sql"))

  desc "code", "Search for the correct 2-letter ISO country code, by search term."
  method_option :search, aliases: "-s", desc: "Phrase or name to search for."
  def code
    codes = File.join(SHARE_PATH, "iso_3166-1.json")
    data = JSON.parse(File.read(codes))
    match = data.select do |item|
      item["name"] =~ Regexp.new(options[:search], Regexp::IGNORECASE)
    end
    match.each do |item|
      puts "#{item['name']}: \033[1m#{item['code']}\033[0m"
    end
  end

  desc "download", "Download the GeoNames data for a specific country."
  method_option :country, aliases: "-c", desc: "Download a specific country's data"
  def download
    path = DATA_PATH
    country = options[:country]
    if country
      puts "Downloading #{country}..."
      `curl -s -o #{path}/#{country}.zip http://download.geonames.org/export/dump/#{country}.zip`
      puts "Unzipping..."
      `unzip -o #{path}/#{country}.zip -d #{path}`
      puts "Data downloaded for #{country_lookup(country)}."
      `rm #{path}/#{country}.zip`
      `rm #{path}/readme.txt`
    else
      puts "No country specified... Use '-c FIPSCODE' to download data for a specific country."
    end
  end

  desc "setup", "Create GeoNames PostGIS tables."
  method_option :connection, aliases: "-c", desc: "Postgres connection name", default: "localhost", required: true
  method_option :database, aliases: "-d", desc: "Database name", required: true
  def setup
    database.run 'CREATE EXTENSION "postgis"' rescue nil
    puts "Creating tables..."
    database.run create_tables
    puts "Creating indexes..."
    database.run create_indexes
    puts "GeoNames tables created."
  end

  desc "import", "Import GeoNames data from raw text"
  method_option :connection, aliases: "-c", desc: "Postgres connection name", default: "localhost", required: true
  method_option :database, aliases: "-d", desc: "Database name", required: true
  method_option :file, aliases: "-f", desc: "File to import", required: true
  def import
    CSV.foreach(options[:file], { col_sep: "\t" }) do |row|
      database[:geoname].insert(row)
    end
    create_geom
  end

  desc "altnames", "Import alternate names data table"
  method_option :connection, aliases: "-c", desc: "Postgres connection name", default: "localhost", required: true
  method_option :database, aliases: "-d", desc: "Database name", required: true
  def altnames
    populate_alternate_names
    puts "Alternate names data imported."
  end

  desc "metadata", "Populate metadata tables"
  method_option :connection, aliases:  "-c", desc: "Postgres connection name", default: "localhost", required: true
  method_option :database, aliases: "-d", desc: "Database name", required: true
  def metadata
    populate_admin1
    puts "Admin 1 names imported."
    populate_admin2
    puts "Admin 2 names imported."
    populate_countryinfo
    puts "Country info imported."
    populate_featurecodes
    puts "Feature codes imported."
    populate_languagecodes
    puts "Language codes imported."
    puts "\033[1mMetadata import complete.\033[0m"
  end

  # desc "country", "Extract a chunk of a GeoNames database by country and insert into a new table."
  # method_option :dbname, aliases:  "-d", desc: => "Database name", :required => true
  # method_option :user, aliases:  "-u", desc: => "Database user name", :required => true
  # method_option :src, aliases:  "-s", desc: => "Source table name", :required => true
  # method_option :dst, aliases:  "-t", desc: => "Destination table name", :required => true
  # method_option :country, aliases:  "-c", desc: => "Country code you want to extract and insert.", :required => true
  # def country
  #   `psql -U #{options[:user]} -d #{options[:dbname]} -c "CREATE TABLE #{options[:dst]} AS SELECT * FROM #{options[:src]} WHERE country = '#{options[:country]}'"`
  # end

  # desc "list", "List countries available in a GeoNames database."
  # method_option :dbname, aliases:  "-d", desc: => "Database name", :required => true
  # method_option :user, aliases:  "-u", desc: => "Database user name", :required => true
  # method_option :table, aliases:  "-t", desc: => "Table containing GeoNames records", :required => true
  # def list
  #   `psql -U #{options[:user]} -d #{options[:dbname]} -c "SELECT DISTINCT country FROM #{options[:table]} ORDER BY country ASC"`
  # end

  no_tasks do

    def database
      settings = YAML.load(File.read(File.expand_path("~/.postgres")))[options[:connection]]
      @db ||= Sequel.connect(adapter: "postgres",
                          host: settings["host"],
                          database: options[:database],
                          user: settings["user"],
                          password: settings["password"])
    end

    def country_lookup(code)
      codes = File.join(SHARE_PATH, "iso_3166-1.json")
      data = JSON.parse(File.read(codes))
      match = data.select do |item|
        item["code"] == code
      end.first["name"]
    end

    def create_tables
      <<-SQL
      create table geoname (
        geonameid int,
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
      ALTER TABLE ONLY geoname
        ADD CONSTRAINT pk_geonameid PRIMARY KEY (geonameid);

      create table alternatename (
        alternatenameid int,
        geonameid int,
        isoLanguage varchar(7),
        alternatename varchar(200),
        ispreferredname boolean,
        isshortname boolean,
        iscolloquial boolean,
        ishistoric boolean
       );
      ALTER TABLE ONLY alternatename
        ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (alternatenameid);

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

      create table countryinfo (
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
        geonameid int,
        neighbors varchar(50),
        equivfipscode varchar(3)
      );
      ALTER TABLE ONLY countryinfo
        ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);

      create table featurecodes (
        code varchar(1),
        class varchar(10),
        fcode varchar (10),
        label varchar(100),
        description varchar(1000)
       );
      ALTER TABLE ONLY featurecodes
        ADD CONSTRAINT pk_fcode PRIMARY KEY (fcode);

      create table languagecodes (
        iso_639_3 varchar(10),
        iso_639_2 varchar(10),
        iso_639_1 varchar(2),
        name varchar(1000)
      );
      ALTER TABLE ONLY languagecodes
        ADD CONSTRAINT pk_languageid PRIMARY KEY (iso_639_3);

      SQL
    end

    def create_indexes
      <<-SQL
        CREATE INDEX index_geoname_on_name ON geoname USING btree (name);
        CREATE INDEX index_geoname_on_altname ON geoname USING btree (alternatenames);
      SQL
    end

    def populate_admin1
      CSV.foreach(File.join(METADATA_PATH, "admin1codes.txt"), { col_sep: "\t" }) do |row|
        database[:admin1codes].insert(row)
      end
    end

    def populate_admin2
      CSV.foreach(File.join(METADATA_PATH, "admin2codes.txt"), { col_sep: "\t" }) do |row|
        database[:admin2codes].insert(row)
      end
    end

    def populate_countryinfo
      CSV.foreach(File.join(METADATA_PATH, "countryinfo.txt"), { col_sep: "\t" }) do |row|
        database[:countryinfo].insert(row)
      end
    end

    def populate_featurecodes
      CSV.foreach(File.join(METADATA_PATH, "featurecodes.txt"), { col_sep: "\t" }) do |row|
        database[:featurecodes].insert(row)
      end
    end

    def populate_languagecodes
      CSV.foreach(File.join(METADATA_PATH, "languagecodes.txt"), { col_sep: "\t" }) do |row|
        database[:languagecodes].insert(row)
      end
    end

    def populate_alternate_names_sql
      CSV.foreach(File.join(DATA_PATH, "alternateNames.txt"), { col_sep: "\t" }) do |row|
        database[:languagecodes].insert(row)
      end
    end

    def create_geom
      database.run "SELECT AddGeometryColumn ('public','geoname','geometry',4326,'POINT',2);"
      database.run "UPDATE geoname SET geometry = ST_PointFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);"
      database.run "CREATE INDEX idx_geoname_geometry ON public.geoname USING gist(geometry);"
    end

  end

end

Gazetteer.start
