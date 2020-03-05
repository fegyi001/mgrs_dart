# mgrs_dart

Utility for converting between WGS84 lat/lng and MGRS coordinates (Dart version of [proj4js/mgrs](https://github.com/proj4js/mgrs)).

## Installing

Add mgrs_dart to `pubspec.yml` (dependencies section), then run `pub get` to download the new dependencies.

```yml
dependencies:
  mgrs_dart: any # or the latest version on Pub
```

## Using

Mgrs_dart has 3 methods

- `toPoint`, takes an mgrs string, returns an array of `[lon,lat]`
- `forward`, takes an array of `[lon,lat]` and optional accuracy and returns an mgrs string
- `inverse`, takes an mgrs string and returns a bbox.

```dart
import 'package:mgrs_dart/mgrs_dart.dart';

void main() {
  var point = [-115.08209766323476, 36.236123461597515];
  var mgrsString = '11SPA7234911844';
  var accuracy = 5;

  // MGRS string to LonLat (results List<double>)
  var calculatedPoint = Mgrs.toPoint(mgrsString);
  print("Mgrs.toPoint('$mgrsString') = $calculatedPoint;");
  // Mgrs.toPoint('11SPA7234911844') = [-115.08209766323476, 36.236123461597515];

  // LonLat to MGRS string (results String)
  var calculatedMgrsString = Mgrs.forward(point, accuracy);
  print("Mgrs.forward($point, $accuracy) = '$calculatedMgrsString';");
  // Mgrs.forward([-115.08209766323476, 36.236123461597515], 5) = '11SPA7234911844';

  // MGRS string to BBOX  (results List<double>)
  var calculatedBox = Mgrs.inverse(mgrsString);
  print("Mgrs.inverse('$mgrsString') = $calculatedBox;");
  // Mgrs.inverse('11SPA7234911844') = [-115.08209766323476, 36.236123461597515, -115.08208632067898, 36.23613229376363];
}
```

## Author

Mgrs_dart was ported from proj4js/mgrs by [Gergely Padányi-Gulyás (@fegyi001)](https://twitter.com/fegyi001) at [Ulyssys Ltd](https://www.ulyssys.hu/index_en.html), Budapest, Hungary.
