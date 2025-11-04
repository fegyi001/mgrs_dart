class UTM {
  final double easting;
  final double northing;
  final String zoneLetter;
  final int zoneNumber;
  final int? accuracy;

  UTM({
    required this.easting,
    required this.northing,
    required this.zoneLetter,
    required this.zoneNumber,
    this.accuracy,
  });

  UTM copyWith({
    double? easting,
    double? northing,
    String? zoneLetter,
    int? zoneNumber,
    int? Function()? accuracy,
  }) {
    return UTM(
      easting: easting ?? this.easting,
      northing: northing ?? this.northing,
      zoneLetter: zoneLetter ?? this.zoneLetter,
      zoneNumber: zoneNumber ?? this.zoneNumber,
      accuracy: accuracy != null ? accuracy() : this.accuracy,
    );
  }

  @override
  String toString() {
    return 'Easting: $easting, northing: $northing, zoneLetter: $zoneLetter, zoneNumber: $zoneNumber, accuracy: $accuracy';
  }
}
