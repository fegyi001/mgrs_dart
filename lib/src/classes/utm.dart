class UTM {
  double easting;
  double northing;
  String zoneLetter;
  int zoneNumber;
  int accuracy;

  UTM(
      {double easting,
      double northing,
      String zoneLetter,
      int zoneNumber,
      int accuracy})
      : easting = easting,
        northing = northing,
        zoneLetter = zoneLetter,
        zoneNumber = zoneNumber,
        accuracy = accuracy;

  @override
  String toString() {
    return 'Easting: $easting, northing: $northing, zoneLetter: $zoneLetter, zoneNumber: $zoneNumber, accuracy: $accuracy';
  }
}
