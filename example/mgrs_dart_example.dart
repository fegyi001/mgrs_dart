// ignore_for_file: avoid_print

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
