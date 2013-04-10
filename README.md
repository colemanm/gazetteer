# Gazetteer
_A set of tools for working with GeoNames data._

[GeoNames](http://www.geonames.org/) is an incredible open dataset of place and geographic feature names, containing almost 10 million geolocated names, available for free. It's compiled from dozens of [sources](http://www.geonames.org/data-sources.html), user submissions and updates. There are a number of [web services](http://www.geonames.org/export/ws-overview.html) and client libraries built for searching and interacting with the data, but working with it in bulk is more difficult.

This tool is designed to simplify the process of getting a local database of GeoNames data running for use in cartographic products or analysis tools. My excuse is for making maps in [TileMill](http://mapbox.com/tilemill).

## Downloading data

There are several tasks in the [Makefile](http://bost.ocks.org/mike/make/) that can download and prepare different data, depending on what you need.

### Full database

Downloading the full database will download and extract the the global GeoNames data, along with all metadata tables. Files are downloaded to the `data` directory in the repo.

```shell
make data
```

### Metadata

GeoNames includes a couple of datasets that augment the placenames data:

* Alternate names - alternate place names in a variety of languages
* ISO language codes - [ISO-639](http://en.wikipedia.org/wiki/ISO_639) codes (parts 1, 2, and 3) for unique languages
* Feature codes - contains the class IDs, codes, titles, and descriptions
* Admin 1 codes - Administrative divisions (e.g. states, provinces)
* Admin 2 codes - Administrative subdivisions (e.g. counties, districts)

Download only metadata tables with:

```shell
make metadata
```

If you only want names data for cities and places (for map labeling purposes), there are maintained subsets of placenames for cities divided by population: cities with population over 1000, 5000, and 15000.

```shell
make cities
```

To clean up the `data/` cache after you've run imports, run `make clean`.

## Usage

**code** - Search for an ISO code by name or partial string:

```shell
./gazetteer code -s "United"    # Returns "US"
```

**createtables** - Create table structures for GeoNames tables in Postgres.

## Other Resources

* [Data sources](http://www.geonames.org/data-sources.html)
* [GeoNames FAQ](http://forum.geonames.org/gforum/forums/show/6.page)
