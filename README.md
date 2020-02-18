# mgrs_dart

Utility for converting between WGS84 lat/lng and MGRS coordinates (Dart version of [proj4js/mgrs](https://github.com/proj4js/mgrs)).

Has 3 methods

- forward, takes an array of `[lon,lat]` and optional accuracy and returns an mgrs string
<!-- - inverse, takes an mgrs string and returns a bbox. -->
- toPoint, takes an mgrs string, returns an array of '[lon,lat]'
