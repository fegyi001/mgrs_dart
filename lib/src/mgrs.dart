import 'dart:math' as math;
import 'package:mgrs_dart/src/classes/bbox.dart';
import 'package:mgrs_dart/src/classes/lonlat.dart';
import 'package:mgrs_dart/src/classes/utm.dart';
import 'package:unicode/unicode.dart' as unicode;

class Mgrs {
  ///
  /// UTM zones are grouped, and assigned to one of a group of 6
  /// sets.
  ///
  /// {int} @private
  ///
  static final NUM_100K_SETS = 6;

  static final ALPHABET = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z'
  ];

  //The column letters (for easting) of the lower left value, per
  //set.
  static final SET_ORIGIN_COLUMN_LETTERS = 'AJSAJS';

  // The row letters (for northing) of the lower left value, per
  // set.
  // {string} @private
  static final SET_ORIGIN_ROW_LETTERS = 'AFAFAF';

  static final A = 65; // A
  static final I = 73; // I
  static final O = 79; // O
  static final V = 86; // V
  static final Z = 90; // Z

  ///
  /// Convert MGRS to lat/lon bounding box.
  ///
  /// @param {string} mgrs MGRS string.
  /// @return {[number,number,number,number]} An array with left longitude),
  ///    bottom (latitude), right
  ///    (longitude) and top (latitude) values in WGS84, representing the
  ///    bounding box for the provided MGRS reference.
  ///
  static List<double> inverse(String mgrs) {
    var bbox = UTMtoLL(decode(mgrs.toUpperCase()));
    if (bbox is LonLat) {
      return [bbox.lon, bbox.lat, bbox.lon, bbox.lat];
    } else if (bbox is BBox) {
      return [bbox.left, bbox.bottom, bbox.right, bbox.top];
    } else {
      throw Exception('Neither bbox, nor lonlat');
    }
  }

  ///
  /// Convert MGRS to lat/lon.
  ///
  static List<double> toPoint(String mgrs) {
    if (mgrs == '') {
      throw Exception('toPoint received a blank string');
    }
    var utm = decode(mgrs.toUpperCase());
    utm.accuracy = null;
    var bbox = UTMtoLL(utm);
    if (bbox is LonLat) {
      return [bbox.lon, bbox.lat];
    } else if (bbox is BBox) {
      return [(bbox.left + bbox.right) / 2, (bbox.top + bbox.bottom) / 2];
    } else {
      throw Exception('Neither bbox, nor lonlat');
    }
  }

  ///
  /// Convert lat/lon to MGRS.
  ///
  /// @param {[number, number]} ll Array with longitude and latitude on a
  ///     WGS84 ellipsoid.
  /// @param {number} [accuracy=5] Accuracy in digits (5 for 1 m, 4 for 10 m, 3 for
  ///      100 m, 2 for 1 km, 1 for 10 km or 0 for 100 km). Optional, default is 5.
  /// @return {string} the MGRS string for the given location and accuracy.
  ///
  static String forward(List<double> ll, int accuracy) {
    accuracy ??= 5;
    if (ll.length != 2) {
      throw Exception(
          'forward received an invalid input: array must contain 2 numbers exactly');
    }
    var lon = ll[0];
    var lat = ll[1];
    if (lon < -180 || lon > 180) {
      throw Exception('forward received an invalid longitude of $lon');
    }
    if (lat < -90 || lat > 90) {
      throw Exception('forward received an invalid latitude of $lat');
    }
    if (lat < -80 || lat > 84) {
      throw Exception(
          'forward received a latitude of $lat, but this library does not support conversions of points in polar regions below 80°S and above 84°N');
    }
    var utm = LLtoUTM(lat, lon);
    return encode(utm, accuracy);
  }

  ///
  /// Encodes a UTM location as MGRS string.
  ///
  /// @private
  /// @param {object} utm An object literal with easting, northing,
  ///     zoneLetter, zoneNumber
  /// @param {number} accuracy Accuracy in digits (0-5).
  /// @return {string} MGRS string for the given UTM location.
  ///
  static String encode(UTM utm, accuracy) {
    // prepend with leading zeroes
    var seasting = '00000${utm.easting.truncate()}';
    var snorthing = '00000${utm.northing.truncate()}';
    var seastingWithAccuracy =
        seasting.substring(seasting.length - 5, seasting.length);
    seastingWithAccuracy =
        seastingWithAccuracy.substring(seastingWithAccuracy.length - accuracy);
    var snorthingWithAccuracy =
        snorthing.substring(snorthing.length - 5, snorthing.length);
    snorthingWithAccuracy = snorthingWithAccuracy
        .substring(snorthingWithAccuracy.length - accuracy);
    var value =
        '${utm.zoneNumber}${utm.zoneLetter}${get100kID(utm.easting, utm.northing, utm.zoneNumber)}$seastingWithAccuracy$snorthingWithAccuracy';
    return value;
  }

  ///
  /// Get the two letter 100k designator for a given UTM easting,
  /// northing and zone number value.
  /// @private
  /// @param {number} easting
  /// @param {number} northing
  /// @param {number} zoneNumber
  /// @return {string} the two letter 100k designator for the given UTM location.
  ///
  static String get100kID(double easting, double northing, int zoneNumber) {
    var setParm = get100kSetForZone(zoneNumber);
    var setColumn = (easting / 100000).floor();
    var setRow = (northing / 100000).floor() % 20;
    return getLetter100kID(setColumn, setRow, setParm);
  }

  ///
  /// Given a UTM zone number, figure out the MGRS 100K set it is in.
  ///
  /// @private
  /// @param {number} i An UTM zone number.
  /// @return {number} the 100k set the UTM zone is in.
  ///
  static int get100kSetForZone(int i) {
    var setParm = i % NUM_100K_SETS;
    if (setParm == 0) {
      setParm = NUM_100K_SETS;
    }
    return setParm;
  }

  ///
  /// Get the two-letter MGRS 100k designator given information
  /// translated from the UTM northing, easting and zone number.
  ///
  /// @private
  /// @param {number} column the column index as it relates to the MGRS
  ///        100k set spreadsheet, created from the UTM easting.
  ///        Values are 1-8.
  /// @param {number} row the row index as it relates to the MGRS 100k set
  ///        spreadsheet, created from the UTM northing value. Values
  ///        are from 0-19.
  /// @param {number} parm the set block, as it relates to the MGRS 100k set
  ///        spreadsheet, created from the UTM zone. Values are from
  ///        1-60.
  /// @return {string} two letter MGRS 100k code.
  ///
  static String getLetter100kID(int column, int row, int parm) {
    // colOrigin and rowOrigin are the letters at the origin of the set
    var index = parm - 1;
    var colOrigin = unicode.toRune(SET_ORIGIN_COLUMN_LETTERS[index]);
    var rowOrigin = unicode.toRune(SET_ORIGIN_ROW_LETTERS[index]);
    // colInt and rowInt are the letters to build to return
    var colInt = colOrigin + column - 1;
    var rowInt = rowOrigin + row;
    var rollover = false;
    if (colInt > Z) {
      colInt = colInt - Z + A - 1;
      rollover = true;
    }
    if (colInt == I ||
        (colOrigin < I && colInt > I) ||
        ((colInt > I || colOrigin < I) && rollover)) {
      colInt++;
    }
    if (colInt == O ||
        (colOrigin < O && colInt > O) ||
        ((colInt > O || colOrigin < O) && rollover)) {
      colInt++;
      if (colInt == I) {
        colInt++;
      }
    }
    if (colInt > Z) {
      colInt = colInt - Z + A - 1;
    }
    if (rowInt > V) {
      rowInt = rowInt - V + A - 1;
      rollover = true;
    } else {
      rollover = false;
    }
    if (((rowInt == I) || ((rowOrigin < I) && (rowInt > I))) ||
        (((rowInt > I) || (rowOrigin < I)) && rollover)) {
      rowInt++;
    }
    if (((rowInt == O) || ((rowOrigin < O) && (rowInt > O))) ||
        (((rowInt > O) || (rowOrigin < O)) && rollover)) {
      rowInt++;
      if (rowInt == I) {
        rowInt++;
      }
    }
    if (rowInt > V) {
      rowInt = rowInt - V + A - 1;
    }
    var twoLetter =
        '${String.fromCharCode(colInt)}${String.fromCharCode(rowInt)}';
    return twoLetter;
  }

  ///
  /// Conversion from degrees to radians.
  ///
  /// @private
  /// @param {number} deg the angle in degrees.
  /// @return {number} the angle in radians.
  ///
  static double degToRad(double deg) {
    return (deg * (math.pi / 180));
  }

  ///
  /// Conversion from radians to degrees.
  ///
  /// @private
  /// @param {number} rad the angle in radians.
  /// @return {number} the angle in degrees.
  ///
  static double radToDeg(double rad) {
    return (180 * (rad / math.pi));
  }

  ///
  /// Converts a set of Longitude and Latitude co-ordinates to UTM
  /// using the WGS84 ellipsoid.
  ///
  /// @private
  /// @param {object} ll Object literal with lat and lon properties
  ///     representing the WGS84 coordinate to be converted.
  /// @return {object} Object literal containing the UTM value with easting,
  ///     northing, zoneNumber and zoneLetter properties, and an optional
  ///     accuracy property in digits. Returns null if the conversion failed.
  ///
  static UTM LLtoUTM(double lat, double lon) {
    var Lat = lat;
    var Long = lon;
    const a = 6378137; //ellip.radius;
    const eccSquared = 0.00669438; //ellip.eccsq;
    const k0 = 0.9996;
    var LatRad = degToRad(Lat);
    var LongRad = degToRad(Long);
    var ZoneNumber = ((Long + 180) / 6).floor() + 1;
    //Make sure the longitude 180 is in Zone 60
    if (Long == 180) {
      ZoneNumber = 60;
    }
    // Special zone for Norway
    if (Lat >= 56 && Lat < 64 && Long >= 3 && Long < 12) {
      ZoneNumber = 32;
    }
    // Special zones for Svalbard
    if (Lat >= 72 && Lat < 84) {
      if (Long >= 0 && Long < 9) {
        ZoneNumber = 31;
      } else if (Long >= 9 && Long < 21) {
        ZoneNumber = 33;
      } else if (Long >= 21 && Long < 33) {
        ZoneNumber = 35;
      } else if (Long >= 33 && Long < 42) {
        ZoneNumber = 37;
      }
    }
    var LongOrigin =
        ((ZoneNumber - 1) * 6 - 180 + 3).toDouble(); // +3 puts origin
    // in middle of zone
    var LongOriginRad = degToRad(LongOrigin);
    var eccPrimeSquared = (eccSquared) / (1 - eccSquared);
    var N = a / math.sqrt(1 - eccSquared * math.sin(LatRad) * math.sin(LatRad));
    var T = math.tan(LatRad) * math.tan(LatRad);
    var C = eccPrimeSquared * math.cos(LatRad) * math.cos(LatRad);
    var A = math.cos(LatRad) * (LongRad - LongOriginRad);
    var M = a *
        ((1 -
                    eccSquared / 4 -
                    3 * eccSquared * eccSquared / 64 -
                    5 * eccSquared * eccSquared * eccSquared / 256) *
                LatRad -
            (3 * eccSquared / 8 +
                    3 * eccSquared * eccSquared / 32 +
                    45 * eccSquared * eccSquared * eccSquared / 1024) *
                math.sin(2 * LatRad) +
            (15 * eccSquared * eccSquared / 256 +
                    45 * eccSquared * eccSquared * eccSquared / 1024) *
                math.sin(4 * LatRad) -
            (35 * eccSquared * eccSquared * eccSquared / 3072) *
                math.sin(6 * LatRad));
    var UTMEasting = (k0 *
            N *
            (A +
                (1 - T + C) * A * A * A / 6 +
                (5 - 18 * T + T * T + 72 * C - 58 * eccPrimeSquared) *
                    A *
                    A *
                    A *
                    A *
                    A /
                    120) +
        500000);
    var UTMNorthing = (k0 *
        (M +
            N *
                math.tan(LatRad) *
                (A * A / 2 +
                    (5 - T + 9 * C + 4 * C * C) * A * A * A * A / 24 +
                    (61 - 58 * T + T * T + 600 * C - 330 * eccPrimeSquared) *
                        A *
                        A *
                        A *
                        A *
                        A *
                        A /
                        720)));
    if (Lat < 0) {
      UTMNorthing += 10000000; // 10000000 meter offset for
      // southern hemisphere
    }
    var utm = UTM(
      easting: UTMEasting.truncateToDouble(),
      northing: UTMNorthing.truncateToDouble(),
      zoneNumber: ZoneNumber,
      zoneLetter: getLetterDesignator(Lat),
    );
    return utm;
  }

  ///
  /// Calculates the MGRS letter designator for the given latitude.
  ///
  /// @private (Not intended for public API, only exported for testing.)
  /// @param {number} latitude The latitude in WGS84 to get the letter designator
  ///     for.
  /// @return {string} The letter designator.
  ///
  static String getLetterDesignator(double latitude) {
    if (latitude <= 84 && latitude >= 72) {
      // the X band is 12 degrees high
      return 'X';
    } else if (latitude < 72 && latitude >= -80) {
      // Latitude bands are lettered C through X, excluding I and O
      const bandLetters = 'CDEFGHJKLMNPQRSTUVWX';
      const bandHeight = 8;
      const minLatitude = -80;
      var index = ((latitude - minLatitude) / bandHeight).floor();
      return bandLetters[index];
    } else if (latitude > 84 || latitude < -80) {
      //This is here as an error flag to show that the Latitude is
      //outside MGRS limits
      return 'Z';
    }
    return null;
  }

  ///
  /// Converts UTM coords to lat/long, using the WGS84 ellipsoid. This is a convenience
  /// class where the Zone can be specified as a single string eg."60N" which
  /// is then broken down into the ZoneNumber and ZoneLetter.
  ///
  /// @private
  /// @param {object} utm An object literal with northing, easting, zoneNumber
  ///     and zoneLetter properties. If an optional accuracy property is
  ///     provided (in meters), a bounding box will be returned instead of
  ///     latitude and longitude.
  /// @return {object} An object literal containing either lat and lon values
  ///     (if no accuracy was provided), or top, right, bottom and left values
  ///     for the bounding box calculated according to the provided accuracy.
  ///     Returns null if the conversion failed.
  ///
  static dynamic UTMtoLL(UTM utm) {
    var UTMNorthing = utm.northing;
    var UTMEasting = utm.easting;
    var zoneLetter = utm.zoneLetter;
    var zoneNumber = utm.zoneNumber;
    // check the ZoneNummber is valid
    if (zoneNumber < 0 || zoneNumber > 60) {
      return null;
    }
    const k0 = 0.9996;
    const a = 6378137; //ellip.radius;
    const eccSquared = 0.00669438; //ellip.eccsq;
    var e1 = (1 - math.sqrt(1 - eccSquared)) / (1 + math.sqrt(1 - eccSquared));
    // remove 500,000 meter offset for longitude
    var x = UTMEasting - 500000;
    var y = UTMNorthing;
    // We must know somehow if we are in the Northern or Southern
    // hemisphere, this is the only time we use the letter So even
    // if the Zone letter isn't exactly correct it should indicate
    // the hemisphere correctly
    if (ALPHABET.indexOf(zoneLetter.toLowerCase()) <
        ALPHABET.indexOf('N'.toLowerCase())) {
      y -= 10000000; // remove 10,000,000 meter offset used
      // for southern hemisphere
    }
    // There are 60 zones with zone 1 being at West -180 to -174
    var LongOrigin = (zoneNumber - 1) * 6 - 180 + 3; // +3 puts origin
    // in middle of zone
    var eccPrimeSquared = (eccSquared) / (1 - eccSquared);
    var M = y / k0;
    var mu = M /
        (a *
            (1 -
                eccSquared / 4 -
                3 * eccSquared * eccSquared / 64 -
                5 * eccSquared * eccSquared * eccSquared / 256));
    var phi1Rad = mu +
        (3 * e1 / 2 - 27 * e1 * e1 * e1 / 32) * math.sin(2 * mu) +
        (21 * e1 * e1 / 16 - 55 * e1 * e1 * e1 * e1 / 32) * math.sin(4 * mu) +
        (151 * e1 * e1 * e1 / 96) * math.sin(6 * mu);
    var N1 =
        a / math.sqrt(1 - eccSquared * math.sin(phi1Rad) * math.sin(phi1Rad));
    var T1 = math.tan(phi1Rad) * math.tan(phi1Rad);
    var C1 = eccPrimeSquared * math.cos(phi1Rad) * math.cos(phi1Rad);
    var R1 = a *
        (1 - eccSquared) /
        math.pow(1 - eccSquared * math.sin(phi1Rad) * math.sin(phi1Rad), 1.5);
    var D = x / (N1 * k0);
    var lat = phi1Rad -
        (N1 * math.tan(phi1Rad) / R1) *
            (D * D / 2 -
                (5 + 3 * T1 + 10 * C1 - 4 * C1 * C1 - 9 * eccPrimeSquared) *
                    D *
                    D *
                    D *
                    D /
                    24 +
                (61 +
                        90 * T1 +
                        298 * C1 +
                        45 * T1 * T1 -
                        252 * eccPrimeSquared -
                        3 * C1 * C1) *
                    D *
                    D *
                    D *
                    D *
                    D *
                    D /
                    720);
    lat = radToDeg(lat);
    var lon = (D -
            (1 + 2 * T1 + C1) * D * D * D / 6 +
            (5 -
                    2 * C1 +
                    28 * T1 -
                    3 * C1 * C1 +
                    8 * eccPrimeSquared +
                    24 * T1 * T1) *
                D *
                D *
                D *
                D *
                D /
                120) /
        math.cos(phi1Rad);
    lon = LongOrigin + radToDeg(lon);
    if (utm.accuracy != null) {
      var topRight = UTMtoLL(
        UTM(
          easting: utm.easting + utm.accuracy,
          northing: utm.northing + utm.accuracy,
          zoneLetter: utm.zoneLetter,
          zoneNumber: utm.zoneNumber,
          accuracy: null,
        ),
      );
      return BBox(
          top: topRight.lat, right: topRight.lon, bottom: lat, left: lon);
    } else {
      return LonLat(lat: lat, lon: lon);
    }
  }

  ///
  /// Decode the UTM parameters from a MGRS string.
  ///
  /// @private
  /// @param {string} mgrsString an UPPERCASE coordinate string is expected.
  /// @return {object} An object literal with easting, northing, zoneLetter,
  ///     zoneNumber and accuracy (in meters) properties.
  ///
  static UTM decode(String mgrsString) {
    if (mgrsString == null || mgrsString.isEmpty) {
      throw Exception('MGRSPoint coverting from nothing');
    }
    //remove any spaces in MGRS String
    mgrsString = mgrsString.replaceAll(' ', '');
    var length = mgrsString.length;
    var hunK;
    var sb = '';
    var i = 0;
    // get Zone number
    for (i; i < 2; i++) {
      var letter = mgrsString[i];
      if (!Mgrs.ALPHABET.contains(letter.toLowerCase())) {
        sb += letter;
      }
    }
    var zoneNumber = int.parse(sb);
    if (i == 0 || i + 3 > length) {
      // A good MGRS string has to be 4-5 digits long,
      // ##AAA/#AAA at least.
      throw Exception('MGRSPoint bad conversion from $mgrsString');
    }
    var zoneLetter = mgrsString[i++];
    // Should we check the zone letter here? Why not.
    if (ALPHABET.indexOf(zoneLetter.toLowerCase()) <=
            ALPHABET.indexOf('A'.toLowerCase()) ||
        zoneLetter == 'B' ||
        zoneLetter == 'Y' ||
        ALPHABET.indexOf(zoneLetter.toLowerCase()) >=
            ALPHABET.indexOf('Z'.toLowerCase()) ||
        zoneLetter == 'I' ||
        zoneLetter == 'O') {
      throw Exception(
          'MGRSPoint zone letter ${zoneLetter} not handled: ${mgrsString}');
    }
    hunK = mgrsString.substring(i, i += 2);
    var set = get100kSetForZone(zoneNumber);
    var east100k = getEastingFromChar(hunK[0], set);
    var north100k = getNorthingFromChar(hunK[1], set);
    // We have a bug where the northing may be 2000000 too low.
    // How do we know when to roll over?
    while (north100k < getMinNorthing(zoneLetter)) {
      north100k += 2000000;
    }
    // calculate the char index for easting/northing separator
    var remainder = length - i;
    if (remainder % 2 != 0) {
      throw Exception(
          'MGRSPoint has to have an even number of digits after the zone letter and two 100km letters - front half for easting meters, second half for northing meters ${mgrsString}');
    }
    var sep = (remainder / 2).truncate();
    var sepEasting = 0.0;
    var sepNorthing = 0.0;
    var accuracyBonus;
    String sepEastingString;
    String sepNorthingString;
    if (sep > 0) {
      accuracyBonus = (100000 / math.pow(10, sep)).round();
      sepEastingString = mgrsString.substring(i, i + sep);
      sepEasting = double.parse(sepEastingString) * accuracyBonus;
      sepNorthingString = mgrsString.substring(i + sep);
      sepNorthing = double.parse(sepNorthingString) * accuracyBonus;
    }
    var easting = sepEasting + east100k;
    var northing = sepNorthing + north100k;
    var utm = UTM(
        easting: easting,
        northing: northing,
        zoneLetter: zoneLetter,
        zoneNumber: zoneNumber,
        accuracy: accuracyBonus);
    return utm;
  }

  ///
  /// Given the first letter from a two-letter MGRS 100k zone, and given the
  /// MGRS table set for the zone number, figure out the easting value that
  /// should be added to the other, secondary easting value.
  ///
  /// @private
  /// @param {string} e The first letter from a two-letter MGRS 100´k zone.
  /// @param {number} set The MGRS table set for the zone number.
  /// @return {number} The easting value for the given letter and set.
  ///
  static int getEastingFromChar(String e, int set) {
    // colOrigin is the letter at the origin of the set for the
    // column
    var curCol = unicode.toRune(SET_ORIGIN_COLUMN_LETTERS[set - 1]);
    var eastingValue = 100000;
    var rewindMarker = false;
    while (curCol != unicode.toRune(e[0])) {
      curCol++;
      if (curCol == I) {
        curCol++;
      }
      if (curCol == O) {
        curCol++;
      }
      if (curCol > Z) {
        if (rewindMarker) {
          throw Exception('Bad character: $e');
        }
        curCol = A;
        rewindMarker = true;
      }
      eastingValue += 100000;
    }
    return eastingValue;
  }

  ///
  /// Given the second letter from a two-letter MGRS 100k zone, and given the
  /// MGRS table set for the zone number, figure out the northing value that
  /// should be added to the other, secondary northing value. You have to
  /// remember that Northings are determined from the equator, and the vertical
  /// cycle of letters mean a 2000000 additional northing meters. This happens
  /// approx. every 18 degrees of latitude. This method does *NOT* count any
  /// additional northings. You have to figure out how many 2000000 meters need
  /// to be added for the zone letter of the MGRS coordinate.
  ///
  /// @private
  /// @param {string} n Second letter of the MGRS 100k zone
  /// @param {number} set The MGRS table set number, which is dependent on the
  ///     UTM zone number.
  /// @return {number} The northing value for the given letter and set.
  ///
  static int getNorthingFromChar(String n, int set) {
    if (ALPHABET.indexOf(n.toLowerCase()) >
        ALPHABET.indexOf('V'.toLowerCase())) {
      throw Exception('MGRSPoint given invalid Northing $n');
    }
    // rowOrigin is the letter at the origin of the set for the
    // column
    var curRow = unicode.toRune(SET_ORIGIN_ROW_LETTERS[set - 1]);
    var northingValue = 0;
    var rewindMarker = false;
    while (curRow != unicode.toRune(n[0])) {
      curRow++;
      if (curRow == I) {
        curRow++;
      }
      if (curRow == O) {
        curRow++;
      }
      // fixing a bug making whole application hang in this loop
      // when 'n' is a wrong character
      if (curRow > V) {
        if (rewindMarker) {
          // making sure that this loop ends
          throw Exception('Bad character: $n');
        }
        curRow = A;
        rewindMarker = true;
      }
      northingValue += 100000;
    }
    return northingValue;
  }

  ///
  /// The function getMinNorthing returns the minimum northing value of a MGRS
  /// zone.
  ///
  /// Ported from Geotrans' c Lattitude_Band_Value structure table.
  ///
  /// @private
  /// @param {string} zoneLetter The MGRS zone to get the min northing for.
  /// @return {number}
  ///
  static int getMinNorthing(String zoneLetter) {
    int northing;
    switch (zoneLetter) {
      case 'C':
        northing = 1100000;
        break;
      case 'D':
        northing = 2000000;
        break;
      case 'E':
        northing = 2800000;
        break;
      case 'F':
        northing = 3700000;
        break;
      case 'G':
        northing = 4600000;
        break;
      case 'H':
        northing = 5500000;
        break;
      case 'J':
        northing = 6400000;
        break;
      case 'K':
        northing = 7300000;
        break;
      case 'L':
        northing = 8200000;
        break;
      case 'M':
        northing = 9100000;
        break;
      case 'N':
        northing = 0;
        break;
      case 'P':
        northing = 800000;
        break;
      case 'Q':
        northing = 1700000;
        break;
      case 'R':
        northing = 2600000;
        break;
      case 'S':
        northing = 3500000;
        break;
      case 'T':
        northing = 4400000;
        break;
      case 'U':
        northing = 5300000;
        break;
      case 'V':
        northing = 6200000;
        break;
      case 'W':
        northing = 7000000;
        break;
      case 'X':
        northing = 7900000;
        break;
      default:
        northing = -1;
    }
    if (northing >= 0) {
      return northing;
    } else {
      throw Exception('Invalid zone letter: $zoneLetter');
    }
  }
}
