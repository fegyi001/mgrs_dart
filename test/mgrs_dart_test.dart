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

    test('Mgrs to LonLat (decode)', () {
      var calculatedPoint = Mgrs.toPoint(mgrsString);
      expect(calculatedPoint[0], point[0]);
      expect(calculatedPoint[1], point[1]);
    });

    test('LonLat to MGRS (encode)', () {
      var calculatedMgrsString = Mgrs.forward(point, 5);
      expect(calculatedMgrsString, mgrsString);
    });
  });
}
