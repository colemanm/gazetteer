#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'json'
require 'yaml'
require 'pg'
require 'sequel'

class Gazetteer < Thor

  SHARE_PATH = File.join(File.dirname(__FILE__), "..", "share")
  DATA_PATH = File.join(File.dirname(__FILE__), "..", "data")
  METADATA_PATH = File.join(File.dirname(__FILE__), "..", "share", "data")
  SQL_PATH = File.join(File.dirname(__FILE__), "..", "share", "sql")

  desc "code", "Search for the correct 2-letter ISO country code, by search term."
  method_option :search, :aliases => "-s", :desc => "Phrase or name to search for."
  def code
    puts "#{connect("magellan")}"
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
  method_option :country, :aliases => "-c", :desc => "Download a specific country's data"
  def download
    path = DATA_PATH
    country = options[:country]
    if country
      puts "Downloading #{country}..."
      `curl -s -o #{path}/#{country}.zip http://download.geonames.org/export/dump/#{country}.zip`
      puts "Unzipping..."
      `unzip #{path}/#{country}.zip -d #{path}`
      puts "Data downloaded for #{country_lookup(country)}."
      `rm #{path}/#{country}.zip`
      `rm #{path}/readme.txt`
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
    `psql -d #{options[:dbname]} -f "#{File.join(SHARE_PATH, 'create_geoname.sql')}"`
    puts "Table \"geoname\" created."

    puts "Creating \"alternatenames\" table..."
    `PGOPTIONS='--client-min-messages=warning' psql -d #{options[:dbname]} -f "#{File.join(SHARE_PATH, 'create_alternate_name.sql')}"`
    puts "Table \"alternatenames\" created."

    puts "Creating \"countryinfo\" table..."
    `PGOPTIONS='--client-min-messages=warning' psql -d #{options[:dbname]} -f "#{File.join(SHARE_PATH, 'create_country_info.sql')}"`
    puts "Table \"countryinfo\" created."

    puts "Setting primary keys..."
    `PGOPTIONS='--client-min-messages=warning' psql -d #{options[:dbname]} -f "#{File.join(SHARE_PATH, 'create_primary_keys.sql')}"`
    puts "Primary keys created."

    puts "Setting foreign keys..."
    `psql -d #{options[:dbname]} -f "#{File.join(SHARE_PATH, 'create_foreign_keys.sql')}"`
    puts "Foreign keys created."

    puts "GeoNames tables created."
  end

  # todo: use sequel to
  desc "altnames", "Import alternate names data table."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  method_option :connection, :aliases => "-c", :desc => "Postgres connection name"
  def altnames
    sql = File.read(File.join(SHARE_PATH, "populate_alternate_name.sql"))
    db = database(options[:connection], options[:dbname])
    # db.run(sql)
    puts populate_alternate_names_sql
    # `psql -d #{options[:dbname]} -c "copy alternatename (alternatenameid,geonameid,isolanguage,alternatename,ispreferredname,isshortname,iscolloquial,ishistoric) from '#{options[:file]}' null as ''"`
  end

  desc "metadata", "Populate metadata tables."
  method_option :dbname, :aliases => "-d", :desc => "Database name", :required => true
  method_option :connection, :aliases => "-c", :desc => "Postgres connection name"
  def metadata
    db = database(options[:connection], options[:dbname])
    db.run create_metadata_tables_sql
    db.run populate_country_info_sql
    db.run populate_feature_codes_sql
    db.run populate_admin1_sql
    db.run populate_admin2_sql
    db.run populate_language_codes_sql
  end

  desc "import", "Import GeoNames data."
  method_option :dbname, :aliases => "-d", :desc => "Database name"
  method_option :cities, :aliases => "-c", :desc => "Import cities data"
  method_option :file, :aliases => "-f", :desc => "GeoNames text file to import, full path"
  def import
    puts "Importing names from #{options[:file]}..."
    conn = PG.connect( dbname: options[:dbname] )
    # conn.exec('COPY geoname ')
    # `psql -d #{options[:dbname]} -c "copy geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from '#{options[:file]}' null as ''"`
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

  no_tasks do

    # Establish a database connection. Reads params from ~/.postgres config in home directory
    def database(server, db)
      options = YAML.load(File.read(File.expand_path("~/.postgres")))[server]
      @db ||= Sequel.connect(adapter: "postgres",
                          host: options["host"],
                          database: db,
                          user: options["user"],
                          password: options["password"])
    end

    def create_alternate_name()
      sql = File.read(File.join(File.dirname(__FILE__), "..", "share", "create_alternate_name.sql"))
    end

    def country_lookup(code)
      codes = File.join(File.dirname(__FILE__) , "..", "share", "iso_3166-1.json")
      data = JSON.parse(File.read(codes))
      match = data.select do |item|
        item["code"] == code
      end.first["name"]
    end

    def populate_alternate_names_sql
      <<-SQL
        copy alternatename (
          alternatenameid,
          geonameid,
          isolanguage,
          alternatename,
          ispreferredname,
          isshortname,
          iscolloquial,
          ishistoric
        ) from '#{File.join(DATA_PATH, "alternateNames.txt")}' null as '';
      SQL
    end

    def create_metadata_tables_sql
      sql = ""
      sql << File.read(File.join(SHARE_PATH, "create_admin1codes.sql"))
      sql << File.read(File.join(SHARE_PATH, "create_admin2codes.sql"))
      sql << File.read(File.join(SHARE_PATH, "create_countryinfo.sql"))
      sql << File.read(File.join(SHARE_PATH, "create_featurecodes.sql"))
      sql << File.read(File.join(SHARE_PATH, "create_languagecodes.sql"))
      sql
    end

    def populate_admin1_sql
      <<-SQL
        copy admin1codes (
          code,
          countrycode,
          admin1_code,
          name,
          alt_name_english,
          geonameid
        ) from '#{File.join(SHARE_PATH, "admin1codes.txt")}' null as '';
      SQL
    end

    def populate_admin2_sql
      <<-SQL
        copy admin2codes (
          code,
          countrycode,
          admin1_code,
          name,
          alt_name_english,
          geonameid
        ) from '#{File.join(SHARE_PATH, "admin2codes.txt")}' null as '';
      SQL
    end

    def populate_country_info_sql
      <<-SQL
        copy countryinfo (
          iso_alpha2,
          iso_alpha3,
          iso_numeric,
          fips_code,
          name,
          capital,
          areainsqkm,
          population,
          continent,
          tld,
          currencycode,
          currencyname,
          phone,
          postalcode,
          postalcoderegex,
          languages,
          geonameid,
          neighbors,
          equivfipscode
        ) from '#{File.join(DATA_PATH, "countryinfo.txt")}' null as '';
      SQL
    end

    def populate_feature_codes_sql
      <<-SQL
        copy featurecodes (
          fcode,
          class,
          code,
          label,
          description
        ) from '#{File.join(SHARE_PATH, "featurecodes.txt")}' null as '';
      SQL
    end

    def populate_language_codes_sql
      <<-SQL
        copy languagecodes (
          iso_639_3,
          iso_639_2,
          iso_639_1,
          name
        ) from '#{File.join(SHARE_PATH, "languagecodes.txt")}' null as '';
      SQL
    end

  end

end

Gazetteer.start
