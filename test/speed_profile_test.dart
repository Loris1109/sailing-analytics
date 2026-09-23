// test/speed_profile_test.dart
// buildSpeedProfile ist rein — der Test braucht weder DB noch Widget.

import 'package:flutter_test/flutter_test.dart';
import 'package:tacktics/data/entities/gps_point.dart';
import 'package:tacktics/data/services/speed_profile.dart';

final _t0 = DateTime(2026, 9, 9, 12);

/// Ein Punkt zur Sekunde [sec] mit Fahrt [sog]. Position und Lage spielen
/// fürs Profil keine Rolle.
GpsPointEntity _p(double sec, double sog) => GpsPointEntity(
  id: '$sec',
  sessionId: 'test',
  timestamp: _t0.add(Duration(milliseconds: (sec * 1000).round())),
  lat: 54.0,
  lon: 10.0,
  sog: sog,
  cog: 0,
  heel: 0,
  pitch: 0,
  magHeading: 0,
  accuracy: 3,
);

void main() {
  test('ohne Punkte gibt es kein Profil', () {
    expect(buildSpeedProfile([]), isNull);
  });

  test('ohne Zeitspanne gibt es keine Achse', () {
    // Alle Punkte auf derselben Sekunde — kam im Wassertest tatsächlich vor.
    expect(buildSpeedProfile([_p(0, 3), _p(0, 4), _p(0, 5)]), isNull);
  });

  test('Balken spannen min und max ihres Fensters auf', () {
    // Zwei Fenster à 50 s: im ersten 2..6 kn, im zweiten konstant 4 kn.
    final points = [
      for (var s = 0; s < 50; s++) _p(s.toDouble(), s.isEven ? 2.0 : 6.0),
      for (var s = 50; s <= 100; s++) _p(s.toDouble(), 4.0),
    ];

    final profile = buildSpeedProfile(points, buckets: 2)!;

    expect(profile.buckets[0]!.min, 2.0);
    expect(profile.buckets[0]!.max, 6.0);
    expect(profile.buckets[0]!.avg, closeTo(4.0, 0.1));
    expect(profile.buckets[1]!.min, 4.0);
    expect(profile.buckets[1]!.max, 4.0);
    expect(profile.maxSog, 6.0);
  });

  test('der letzte Punkt landet im letzten Fenster, nicht daneben', () {
    final profile = buildSpeedProfile([_p(0, 1), _p(10, 9)], buckets: 4)!;

    expect(profile.buckets.length, 4);
    expect(profile.buckets.last!.max, 9.0);
  });

  test('ein Fenster ohne Punkte bleibt eine Lücke', () {
    // 100 s Aufzeichnung auf vier Fenster à 25 s, aber zwischen 24 s und
    // 76 s kein einziger Fix — die beiden mittleren bleiben leer.
    final points = [
      for (var s = 0; s <= 24; s++) _p(s.toDouble(), 5.0),
      for (var s = 76; s <= 100; s++) _p(s.toDouble(), 5.0),
    ];

    final profile = buildSpeedProfile(points, buckets: 4)!;

    expect(profile.buckets[0], isNotNull);
    expect(profile.buckets[1], isNull);
    expect(profile.buckets[2], isNull);
    expect(profile.buckets[3], isNotNull);
  });

  test('die Zeitachse rechnet auf die Punktgrenzen, nicht auf die Fenster', () {
    final profile = buildSpeedProfile([_p(0, 3), _p(100, 3)], buckets: 10)!;

    expect(profile.timeAt(0), _t0);
    expect(profile.timeAt(0.5), _t0.add(const Duration(seconds: 50)));
    expect(profile.timeAt(1), _t0.add(const Duration(seconds: 100)));
    // Über die Ränder hinaus bleibt die Achse stehen — ein Griff, der über
    // den Rand gezogen wird, darf keinen Zeitpunkt außerhalb liefern.
    expect(profile.timeAt(-0.5), _t0);
    expect(profile.timeAt(2), _t0.add(const Duration(seconds: 100)));
  });
}
