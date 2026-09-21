// lib/data/services/trim.dart
// Der Ausschnitt einer Session als Zeitspanne, plus das Anwenden auf eine
// Punktliste. Rein: kein Flutter, keine DB, keine Provider.

import 'package:tacktics/data/entities/gps_point.dart';

/// Der sichtbare Teil einer Session.
///
/// Bewusst eine Zeitspanne und keine Indizes: der Ausschnitt entsteht am
/// Speed-Profil, dessen Achse die Zeit ist, und er soll eine Session
/// überdauern, deren Punktliste sich noch ändern kann (nachgeladene Punkte,
/// später ein dauerhafter Schnitt).
class TrimRange {
  final DateTime start;
  final DateTime end;

  const TrimRange(this.start, this.end);

  bool contains(DateTime t) => !t.isBefore(start) && !t.isAfter(end);

  /// Der Ausschnitt aus einer nach Zeit SORTIERTEN Punktliste, wie sie aus
  /// `getPointsForSession` kommt (ORDER BY timestamp ASC).
  ///
  /// Über zwei binäre Suchen statt über einen Filterdurchlauf: beim Ziehen
  /// am Griff läuft das je Frame, und eine Session hat zehntausende Punkte.
  /// Liegt der Ausschnitt auf der ganzen Session, kommt die Liste unverändert
  /// zurück — dann entsteht nicht einmal eine Kopie.
  List<GpsPointEntity> apply(List<GpsPointEntity> points) {
    if (points.isEmpty) return points;
    final lo = _lowerBound(points, start);
    final hi = _upperBound(points, end);
    if (lo >= hi) return const [];
    if (lo == 0 && hi == points.length) return points;
    return points.sublist(lo, hi);
  }

  /// Erster Index mit `timestamp >= t`.
  static int _lowerBound(List<GpsPointEntity> points, DateTime t) {
    var lo = 0, hi = points.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (points[mid].timestamp.isBefore(t)) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Erster Index mit `timestamp > t`.
  static int _upperBound(List<GpsPointEntity> points, DateTime t) {
    var lo = 0, hi = points.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (points[mid].timestamp.isAfter(t)) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  /// Wertgleichheit, damit ein Zug am Griff, der am Anschlag hängen bleibt,
  /// keinen neuen Zustand erzeugt — sonst baut die Karte bei jedem Frame
  /// ihre Polylinien neu, obwohl sich nichts geändert hat.
  @override
  bool operator ==(Object other) =>
      other is TrimRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
