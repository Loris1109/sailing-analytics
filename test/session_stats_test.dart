// test/session_stats_test.dart
// computeSessionStats ist rein — der Test braucht weder DB noch Widget.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/data/services/session_stats.dart';

final _t0 = DateTime(2026, 9, 9, 12);

/// Baut einen Track aus (Dauer [s], Speed [kn], Kurs [°])-Abschnitten.
/// Die Position wird aus Speed und Kurs integriert, damit Punktabstand und
/// Distanz zueinander passen. [gapAfterSec] schneidet 30 s heraus.
List<GpsPointEntity> _track(
  List<(double, double, double)> legs, {
  double hz = 4,
  double gapAfterSec = -1,
}) {
  final pts = <GpsPointEntity>[];
  var t = 0.0, lat = 54.0, lon = 10.0;
  for (final (dur, sog, cog) in legs) {
    for (var s = 0.0; s < dur; s += 1 / hz) {
      if (gapAfterSec > 0 && t > gapAfterSec && t < gapAfterSec + 30) {
        t += 1 / hz;
        continue;
      }
      pts.add(
        GpsPointEntity(
          id: '${pts.length}',
          sessionId: 'test',
          timestamp: _t0.add(Duration(milliseconds: (t * 1000).round())),
          lat: lat,
          lon: lon,
          sog: sog,
          cog: cog,
          heel: 0,
          pitch: 0,
          magHeading: cog,
          accuracy: 3,
        ),
      );
      final mps = sog * 0.514444;
      lat += mps * cos(cog * pi / 180) / hz / 111320;
      lon += mps * sin(cog * pi / 180) / hz / 111320 / cos(lat * pi / 180);
      t += 1 / hz;
    }
  }
  return pts;
}

SessionStats _stats(List<GpsPointEntity> pts) =>
    computeSessionStats(pts, tackAngleDeg: 90);

void main() {
  test('Wendewinkel 90° ergibt eine Schwelle von 63°', () {
    expect(maneuverThresholdDeg(90), closeTo(63, 0.01));
    // Boden greift bei unsinnig kleinen Eingaben
    expect(maneuverThresholdDeg(20), 35);
  });

  group('Spitzenspeed', () {
    test('ein 3-s-Burst kommt voll durch', () {
      final s = _stats(_track([(60, 5, 0), (3, 9, 0), (60, 5, 0)]));
      expect(s.peakSpeed, closeTo(9.0, 0.1));
    });

    test('ein einzelner GPS-Ausreisser wird nicht zum Rekord', () {
      // Das ist der Grund für das 2-s-Fenster: ein Sample mit 20 kn darf
      // keinen Fantasie-Rekord erzeugen.
      final s = _stats(_track([(60, 5, 0), (0.25, 20, 0), (60, 5, 0)]));
      expect(s.peakSpeed, lessThan(8.0));
    });

    test('zu kurze Session liefert null statt einer Scheinzahl', () {
      expect(_stats(_track([(1, 5, 0)])).peakSpeed, isNull);
    });
  });

  group('Ø fahrend', () {
    test('Stillstand zählt weder in Schnitt noch in Fahrtzeit', () {
      // Punktschnitt über alles wäre 2,55 kn — die Zahl, die vorher in der
      // Leiste stand.
      final s = _stats(_track([(60, 5, 0), (60, 0.1, 0)]));
      expect(s.avgMovingSpeed, closeTo(5.0, 0.1));
      expect(s.movingTime.inSeconds, closeTo(60, 2));
    });

    test('eine GPS-Lücke wird nicht als Fahrtzeit gezählt', () {
      final s = _stats(_track([(120, 5, 0)], gapAfterSec: 40));
      expect(s.movingTime.inSeconds, closeTo(90, 2));
    });
  });

  group('Wenden', () {
    test('fünf Wenden auf einem Kreuz werden gezählt', () {
      final beat = <(double, double, double)>[];
      var cog = 45.0;
      for (var i = 0; i < 6; i++) {
        beat.add((30, 4.5, cog));
        if (i == 5) break;
        final target = cog == 45.0 ? -45.0 : 45.0;
        for (var k = 1; k <= 8; k++) {
          beat.add((0.5, 2.5, (cog + (target - cog) * k / 8 + 360) % 360));
        }
        cog = (target + 360) % 360;
      }
      expect(_stats(_track(beat)).tacks, 5);
    });

    test('langsames Eindrehen über 120 s ist keine Wende', () {
      final slow = [
        for (var k = 0; k <= 120; k++) (1.0, 4.5, k * 90 / 120),
      ];
      expect(_stats(_track(slow)).tacks, 0);
    });

    test('eine GPS-Lücke erzeugt keine Phantomwende', () {
      expect(_stats(_track([(120, 5, 0)], gapAfterSec: 40)).tacks, 0);
    });
  });

  test('leere und einelementige Liste sind unkritisch', () {
    expect(_stats([]).tacks, 0);
    expect(_stats([]).distanceMeters, 0);
    expect(_stats(_track([(0.25, 5, 0)])).peakSpeed, isNull);
  });
}
