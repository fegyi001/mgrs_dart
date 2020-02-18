import 'package:mgrs_dart/mgrs_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MGRS test', () {
    List<double> point;
    String mgrsString;

    setUp(() {
      point = [-115.08209766323476, 36.236123461597515];
      mgrsString = '11SPA7234911844';
    });

    test('toPoint(): MGRS to LonLat', () {
      var calculatedPoint = Mgrs.toPoint(mgrsString);
      expect(calculatedPoint[0], point[0]);
      expect(calculatedPoint[1], point[1]);
    });

    test('forward(): LonLat to MGRS', () {
      var calculatedMgrsString = Mgrs.forward(point, 5);
      expect(calculatedMgrsString, mgrsString);
    });

    test('inverse(): MGRS to BBOX ', () {
      var calculatedBox = Mgrs.inverse(mgrsString);
      expect(
          calculatedBox.toString(),
          [
            -115.08209766323476,
            36.236123461597515,
            -115.08208632067898,
            36.23613229376363
          ].toString());
    });
  });
}
