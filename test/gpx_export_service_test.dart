import 'package:flutter_test/flutter_test.dart';
import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/data/entities/session.dart';
import 'package:sailing_analytics/data/services/gpx_export_service.dart';

void main() {
  final service = GpxExportService();

  final session = SessionEntity(
    id: 's1',
    name: 'Wind < 5kn & Welle',
    boatId: 'b1',
    startTime: DateTime(2026, 6, 10, 14, 3), // lokale Zeit
  );

  const boat = BoatEntity(
    id: 'b1',
    name: 'Pixel',
    sailNumber: 'GER 1234',
    boatClass: 'Laser',
    maxSpeed: 10,
    isActive: true,
  );

  final points = [
    GpsPointEntity(
      sessionId: 's1',
      timestamp: DateTime.utc(2026, 6, 10, 12, 3, 1),
      lat: 54.123456789,
      lon: 10.567891234,
      sog: 5.43,
      cog: 182.0,
      heel: -12.34,
      pitch: 0,
      magHeading: 180,
      accuracy: 4,
    ),
  ];

  group('buildGpx', () {
    test('escaped Session-Namen in name-Elementen', () {
      final gpx = service.buildGpx(session, boat, points);
      expect(gpx, contains('<name>Wind &lt; 5kn &amp; Welle</name>'));
      expect(gpx, isNot(contains('<name>Wind < 5kn')));
    });

    test('schreibt trkpt mit lat/lon-Attributen und UTC-Zeit', () {
      final gpx = service.buildGpx(session, boat, points);
      expect(gpx, contains('<trkpt lat="54.123457" lon="10.567891">'));
      expect(gpx, contains('<time>2026-06-10T12:03:01.000Z</time>'));
    });

    test('enthält Bootsinfos in metadata-extensions und desc', () {
      final gpx = service.buildGpx(session, boat, points);
      expect(gpx, contains('<st:sailNumber>GER 1234</st:sailNumber>'));
      expect(gpx, contains('<st:class>Laser</st:class>'));
      expect(gpx, contains('<desc>Laser – GER 1234 (Pixel)</desc>'));
    });

    test('lässt Bootsblock weg wenn boat null ist', () {
      final gpx = service.buildGpx(session, null, points);
      expect(gpx, isNot(contains('<st:boat>')));
      expect(gpx, isNot(contains('<desc>')));
    });

    test('schreibt SOG/COG/Heel als Punkt-Extensions', () {
      final gpx = service.buildGpx(session, boat, points);
      expect(gpx, contains('<st:sog>5.4</st:sog>'));
      expect(gpx, contains('<st:cog>182.0</st:cog>'));
      expect(gpx, contains('<st:heel>-12.3</st:heel>'));
    });

    test('exportiert Windrichtung als Metadatum, aber kein TWA/VMG', () {
      final withWind = session.copyWith(windDirection: 185.0);
      final gpx = service.buildGpx(withWind, boat, points);
      expect(gpx, contains('<st:windDirection>185.0</st:windDirection>'));
      expect(gpx, isNot(contains('twa')));
      expect(gpx, isNot(contains('vmg')));
    });

    test('lässt Windrichtung weg wenn nicht gesetzt', () {
      final gpx = service.buildGpx(session, boat, points);
      expect(gpx, isNot(contains('windDirection')));
    });

    test('Wind ohne Boot ergibt trotzdem geschlossenes extensions-Element', () {
      final withWind = session.copyWith(windDirection: 185.0);
      final gpx = service.buildGpx(withWind, null, points);
      expect(gpx, contains('<st:windDirection>185.0</st:windDirection>'));
      expect(gpx, contains('</extensions>'));
      expect(gpx, isNot(contains('<st:boat>')));
    });
  });

  group('fileNameFor', () {
    test('macht den Namen dateisystem-sicher', () {
      expect(service.fileNameFor(session), 'Wind_5kn_Welle.gpx');
    });
  });
}
