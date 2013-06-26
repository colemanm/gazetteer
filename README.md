# Gazetteer
_A set of tools for working with GeoNames data._

[GeoNames](http://www.geonames.org/) is an incredible open dataset of place and geographic feature names, containing almost 10 million geolocated names, available for free. It's compiled from dozens of [sources](http://www.geonames.org/data-sources.html), user submissions, and updates. There are a number of [web services](http://www.geonames.org/export/ws-overview.html) and client libraries built for searching and interacting with the data, but working with it in bulk is more difficult.

This tool is designed to simplify the process of getting a local database of GeoNames data running for use in cartographic products or analysis tools. My excuse is for making maps in [TileMill](http://mapbox.com/tilemill), and to have a detailed placename datastore to use as map overlay in QGIS.

## Downloading Data

There are several tasks in the [Makefile](http://bost.ocks.org/mike/make/) that can download and prepare different data, depending on what you need.

### Global Dataset

Downloading the full database will download and extract the the global GeoNames data, along with all metadata tables. Files are downloaded to the `data` directory in the repo.

```shell
make data
```

The full data download includes the full current snapshot of all features, the alternate names lookup table (for multilingual labeling or toponymological analysis), and the large city datasets, for convenience.

### Metadata

GeoNames includes a couple of datasets that augment the placenames data, like admin boundary relationships and feature codes.

* Alternate names - alternate place names in a variety of languages
* ISO language codes - [ISO-639](http://en.wikipedia.org/wiki/ISO_639) codes (parts 1, 2, and 3) for unique languages
* Feature codes - contains the class IDs, codes, titles, and descriptions
* Admin 1 codes - Administrative divisions (e.g. states, provinces)
* Admin 2 codes - Administrative subdivisions (e.g. counties, districts)

### Cities

If you only want names data for cities and places (for map labeling purposes), there are maintained subsets of placenames for cities divided by population: cities with population over 1000, 5000, and 15000.

```shell
make cities
```

To clean up the `data/` cache after you've run imports, run `make clean`.

## Usage

To stage up a place to store your GeoNames data, first make a PostgreSQL database:

    createdb geonames

When you have a place to put the data, here are some of the tasks you can run to get moving with some data:

* `./gazetteer.rb setup -d geonames` - This step is required for all the other tasks. This populates your database with the proper tables and database schema.
* `./gazetteer.rb code -s "alb"` - The `code` task takes a search term (like "alb"), and returns the proper ISO country codes for any results (like "Albania" and "Svalbard").
* `./gazetteer.rb download -c AL` - Download a single country of GeoNames data by country code.
* `./gazetter.rb metadata -d geonames` - Populate your database with placename metadata, like language, feature, and admin codes. Useful for JOINing other info to your placename tables.
* 

**code** - Search for an ISO code by name or partial string:

```shell
$ ./gazetteer.rb code -s Alb
Albania: **AL**
Svalbard and Jan Mayen: **SJ**
```

## Other Resources

* [Data sources](http://www.geonames.org/data-sources.html)
* [GeoNames FAQ](http://forum.geonames.org/gforum/forums/show/6.page)

## License

BSD. GeoNames data is [CC-BY](http://creativecommons.org/licenses/by/3.0/).