# Gazetteer
_A set of tools for working with GeoNames data._

## Downloading data

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

### Cities

If you only want names data for cities and places (for map labeling purposes), there are maintained subsets of placenames for cities divided by population: cities with population over 1000, 5000, and 15000.

```shell
make cities
```
