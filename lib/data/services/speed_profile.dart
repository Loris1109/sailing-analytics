// lib/data/services/speed_profile.dart
// Die Punktliste einer Session, heruntergerechnet auf eine Handvoll Balken —
// Grundlage für das Profil unter dem Trim-Brush.
// Rein: kein Flutter, keine DB, keine Provider — direkt unit-testbar.

import 'package:tacktics/data/entities/gps_point.dart';

/// Wie viele Balken das Profil hat.
///
/// Fest, nicht aus der Pixelbreite abgeleitet: sonst müsste der Provider auf
/// die Breite gekeyt werden und bei jeder Layoutänderung — Drehung, anderes
/// Gerät, aufgezogenes Panel — die ganze Session neu durchlaufen. 240 Balken
/// sind auf jedem Telefon feiner als die Leiste breit ist; der Painter zieht
/// sie auf die vorhandenen Pixel.
const kSpeedProfileBuckets = 240;

/// Was in einem Zeitfenster gefahren wurde.
///
/// [min] und [max] spannen den Balken auf. Genau dieser Abstand ist das
/// Signal, um das es geht: auf einem Regattakurs liegen in 30 s Anlieger und
/// Wende nebeneinander, das Band wird dick. Auf der Anfahrt läuft das Boot
/// konstant, das Band schrumpft zu einer Linie.
class SpeedBucket {
  final double min;
  final double max;

  /// Einfaches Mittel über die Punkte im Fenster, NICHT zeitgewichtet und
  /// ohne Stillstandsfilter — nur die Einfärbung des Balkens hängt daran.
  /// Nichts hier ist eine Kennzahl; die kommen aus session_stats.dart.
  final double avg;

  const SpeedBucket({required this.min, required this.max, required this.avg});
}

/// Das fertige Profil einer Session.
class SpeedProfile {
  /// Zeitachse des Profils — der erste und der letzte Punkt der Session.
  /// Die Balken teilen genau diese Spanne in gleich lange Fenster.
  final DateTime start;
  final DateTime end;

  /// Ein Eintrag je Fenster, `null` wo kein einziger Punkt liegt: GPS-
  /// Aussetzer, Gerät in der Tasche. Bewusst als Lücke gezeichnet statt
  /// überbrückt — eine gerade Linie über zehn Minuten ohne Fix wäre eine
  /// Behauptung, die die Daten nicht hergeben.
  final List<SpeedBucket?> buckets;

  /// Schnellster Punkt der Session, Obergrenze der Höhenachse.
  final double maxSog;

  const SpeedProfile({
    required this.start,
    required this.end,
    required this.buckets,
    required this.maxSog,
  });

  Duration get duration => end.difference(start);

  /// Der Zeitpunkt an der relativen Position [t] (0 = links, 1 = rechts).
  /// Die Umrechnung, die der Brush später braucht, gehört hierher: sie muss
  /// zur Einteilung der Balken passen, und die entsteht hier.
  DateTime timeAt(double t) => start.add(
    Duration(
      microseconds: (duration.inMicroseconds * t.clamp(0.0, 1.0)).round(),
    ),
  );

  /// Die Gegenrichtung zu [timeAt]: wo auf der Achse ein Zeitpunkt liegt.
  /// Braucht der Brush, um gesetzte Grenzen wieder als Griffe zu zeichnen.
  double fractionAt(DateTime t) {
    final total = duration.inMicroseconds;
    if (total <= 0) return 0.0;
    return (t.difference(start).inMicroseconds / total).clamp(0.0, 1.0);
  }
}

/// Rechnet [points] auf [buckets] gleich lange ZEITfenster herunter.
///
/// Zeit, nicht Index: die Achse trägt später die Brush-Grenzen, und die sind
/// Zeitpunkte. Über den Index gebucketet würde eine Aufzeichnungspause die
/// Achse stauchen — bei Sessions mit doppelten Zeitstempeln oder wechselnder
/// Abtastrate läge der Griff dann woanders als die Anzeige verspricht.
///
/// Gibt `null` zurück, wenn sich keine Achse aufspannen lässt: keine Punkte,
/// oder alle mit demselben Zeitstempel.
///
/// Erwartet die Punkte nach Zeit sortiert, wie sie aus
/// `getPointsForSession` kommen (ORDER BY timestamp ASC).
SpeedProfile? buildSpeedProfile(
  List<GpsPointEntity> points, {
  int buckets = kSpeedProfileBuckets,
}) {
  if (points.isEmpty) return null;

  final start = points.first.timestamp;
  final end = points.last.timestamp;
  final totalMicros = end.difference(start).inMicroseconds;
  if (totalMicros <= 0) return null;

  final mins = List<double>.filled(buckets, double.infinity);
  final maxs = List<double>.filled(buckets, double.negativeInfinity);
  final sums = List<double>.filled(buckets, 0.0);
  final counts = List<int>.filled(buckets, 0);
  var maxSog = 0.0;

  for (final p in points) {
    final elapsed = p.timestamp.difference(start).inMicroseconds;
    // Der letzte Punkt landet rechnerisch auf `buckets` — der clamp fängt
    // ihn im letzten Fenster ab, statt einen eigenen Sonderfall zu brauchen.
    final i = (elapsed * buckets ~/ totalMicros).clamp(0, buckets - 1);

    final sog = p.sog;
    if (!sog.isFinite) continue;
    if (sog < mins[i]) mins[i] = sog;
    if (sog > maxs[i]) maxs[i] = sog;
    sums[i] += sog;
    counts[i]++;
    if (sog > maxSog) maxSog = sog;
  }

  return SpeedProfile(
    start: start,
    end: end,
    maxSog: maxSog,
    buckets: [
      for (var i = 0; i < buckets; i++)
        if (counts[i] == 0)
          null
        else
          SpeedBucket(min: mins[i], max: maxs[i], avg: sums[i] / counts[i]),
    ],
  );
}
