// test/gpx_export_test.dart
// buildGpx ist reine Stringlogik — der Test braucht weder DB noch Widget.

import 'package:flutter_test/flutter_test.dart';
import 'package:tacktics/data/entities/boat.dart';
import 'package:tacktics/data/entities/gps_point.dart';
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
}
