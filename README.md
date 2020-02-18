# mgrs_dart

Utility for converting between WGS84 lat/lng and MGRS coordinates (Dart version of [proj4js/mgrs](https://github.com/proj4js/mgrs)).

Has 2 methods

- forward, takes an array of `[lon,lat]` and optional accuracy and returns an mgrs string
<!-- - inverse, takes an mgrs string and returns a bbox. -->
- toPoint, takes an mgrs string, returns an array of `[lon,lat]`

```dart
  List<double> point = [-115.08209766323476, 36.236123461597515];
  String mgrsString = '11SPA7234911844';
  int accuracy = 5;

  // toPoint
  var calculatedPoint = Mgrs.toPoint(mgrsString);
  print('Mgrs.toPoint($mgrsString) = $calculatedPoint');

  // forward
  var calculatedMgrsString = Mgrs.forward(point, accuracy);
  print('Mgrs.forward($point, $accuracy) = $calculatedMgrsString');
```
