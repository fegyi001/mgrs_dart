import 'package:mgrs_dart/mgrs_dart.dart';

void main() {
  List<double> point = [-115.08209766323476, 36.236123461597515];
  String mgrsString = '11SPA7234911844';
  int accuracy = 5;

  // toPoint()
  var calculatedPoint = Mgrs.toPoint(mgrsString);
  print("Mgrs.toPoint('$mgrsString') = $calculatedPoint;");

  // forward()
  var calculatedMgrsString = Mgrs.forward(point, accuracy);
  print("Mgrs.forward($point, $accuracy) = '$calculatedMgrsString';");

  // inverse()
  var calculatedBox = Mgrs.inverse(mgrsString);
  print("Mgrs.inverse('$mgrsString') = $calculatedBox;");
}
