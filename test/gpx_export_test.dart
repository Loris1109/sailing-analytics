// test/gpx_export_test.dart
// buildGpx ist reine Stringlogik — der Test braucht weder DB noch Widget.

import 'package:flutter_test/flutter_test.dart';
import 'package:tacktics/data/entities/boat.dart';
import 'package:tacktics/data/entities/gps_point.dart';
import 'package:tacktics/data/entities/range_measurements.dart';
import 'package:tacktics/data/entities/session.dart';
import 'package:tacktics/data/services/gpx_export_service.dart';

final _t0 = DateTime.utc(2026, 9, 9, 12);

final _session = SessionEntity(
  id: 's1',
  name: 'Uckermark Open Tag 1',
  boatId: 'b1',
  startTime: _t0,
  endTime: _t0.add(const Duration(hours: 6)),
);

const _boat = BoatEntity(
  id: 'b1',
  sailNumber: 'GER 123',
  name: 'Wilma',
  boatClass: 'Europe',
  maxSpeed: 12,
  tackAngle: 90,
  isActive: true,
);

/// Punkte ab Minute [fromMin], einer je Minute.
List<GpsPointEntity> _points(int fromMin, int count) => [
  for (var i = 0; i < count; i++)
    GpsPointEntity(
      id: '${fromMin + i}',
      sessionId: 's1',
      timestamp: _t0.add(Duration(minutes: fromMin + i)),
      lat: 53.3,
      lon: 13.9,
      sog: 4,
      cog: 200,
      heel: 0,
      pitch: 0,
      magHeading: 200,
      accuracy: 3,
    ),
];

void main() {
  final service = GpxExportService();

  test('ganze Session: Titel und Zeit kommen von der Session', () {
    final gpx = service.buildGpx(_session, _boat, _points(0, 3), []);

    expect(gpx, contains('<name>Uckermark Open Tag 1</name>'));
    expect(gpx, contains('<time>2026-09-09T12:00:00.000Z</time>'));
    // Ohne Ausschnitt steht in der Beschreibung nur das Boot.
    expect(gpx, contains('<desc>Europe – GER 123 (Wilma)</desc>'));
  });

  test('Ausschnitt: Titel ist der Ausschnitt, die Session bleibt als Herkunft', () {
    final gpx = service.buildGpx(
      _session,
      _boat,
      _points(90, 3),
      [],
      clipName: 'Rennen 2',
    );

    expect(gpx, contains('<name>Rennen 2</name>'));
    expect(gpx, contains('Ausschnitt aus Uckermark Open Tag 1'));
    expect(gpx, contains('Europe – GER 123 (Wilma)'));
    // Nicht mehr 12:00 — die Spur beginnt beim ersten Punkt des Ausschnitts.
    expect(gpx, contains('<time>2026-09-09T13:30:00.000Z</time>'));
    expect(gpx, isNot(contains('<name>Uckermark Open Tag 1</name>')));
  });

  test('ohne Boot bleibt die Beschreibung weg', () {
    final gpx = service.buildGpx(_session, null, _points(0, 2), []);
    expect(gpx, isNot(contains('<desc>')));
  });

  test('Dateiname trennt zwei Ausschnitte derselben Session', () {
    expect(
      service.fileNameFor(_session),
      'Uckermark_Open_Tag_1.gpx',
    );
    expect(
      service.fileNameFor(_session, clipName: 'Rennen 2'),
      'Uckermark_Open_Tag_1_Rennen_2.gpx',
    );
    expect(
      service.fileNameFor(_session, clipName: '12:30–13:15'),
      'Uckermark_Open_Tag_1_12_30_13_15.gpx',
    );
  });

  test('Sonderzeichen im Namen werden escaped', () {
    final session = _session.copyWith(name: 'Tag 1 & 2 <Test>');
    final gpx = service.buildGpx(session, null, _points(0, 2), []);

    expect(gpx, contains('<name>Tag 1 &amp; 2 &lt;Test&gt;</name>'));
  });

  test('mehrere BLE-Pakete je Punkt: jedes unter seinem Punkt, mit eigener Zeit', () {
    RangeMeasurementEntity ble(String pointId, int ms, int rssi) =>
        RangeMeasurementEntity(
          id: '$pointId-$ms',
          sessionId: 's1',
          gpsPointId: pointId,
          peerId: 'GER 7',
          tech: 'ble',
          rssi: rssi,
          timestamp: _t0.add(Duration(milliseconds: ms)),
        );

    final gpx = service.buildGpx(_session, _boat, _points(0, 2), [
      ble('0', 100, -60),
      ble('0', 200, -61),
      ble('1', 60100, -70),
      ble('0', 300, -62),
      // Punkt gehört nicht zum Export (z. B. außerhalb eines Ausschnitts)
      ble('99', 999, -99),
    ]);

    // [0] ist der Kopf, [1] und [2] die beiden Punkte
    final trkpts = gpx.split('<trkpt ');
    expect(trkpts, hasLength(3));

    final first = trkpts[1];
    expect('<st:measurement>'.allMatches(first), hasLength(3));
    expect(first, contains('<st:time>2026-09-09T12:00:00.100Z</st:time>'));
    expect(first, contains('<st:time>2026-09-09T12:00:00.300Z</st:time>'));
    expect(first, contains('<st:rssi>-62</st:rssi>'));

    final second = trkpts[2];
    expect('<st:measurement>'.allMatches(second), hasLength(1));
    expect(second, contains('<st:time>2026-09-09T12:01:00.100Z</st:time>'));
    expect(second, contains('<st:rssi>-70</st:rssi>'));

    expect(gpx, isNot(contains('<st:rssi>-99</st:rssi>')));
  });
}
