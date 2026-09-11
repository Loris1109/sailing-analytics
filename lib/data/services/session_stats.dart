// lib/data/services/session_stats.dart
// Alle Kennzahlen einer abgeschlossenen Session in EINEM Durchlauf.
// Rein: kein Flutter, keine DB, keine Provider — direkt unit-testbar.
//
// Gerechnet wird einmal beim Beenden der Session (SessionRepository.
// completeSession), das Ergebnis landet als Spalten in `sessions`. Die UI
// liest nur noch Felder — sie fasst die Punktliste nicht mehr an.

import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';

/// Version des Algorithmus. Hochzählen, sobald sich an der Rechnung unten
/// etwas ändert — Sessions mit kleinerer Version werden beim App-Start
/// nachgerechnet (SessionRepository.recomputeOutdatedStats).
///
/// Auch hochzählen, wenn sich eine der Konstanten ändert: die Werte in der
/// DB sind eingefroren und wissen nichts davon.
const sessionStatsVersion = 1;

/// Wendewinkel für Sessions, deren Boot gelöscht wurde — `boatId` ist
/// nullable, die Aufzeichnung überlebt das Boot.
const kDefaultTackAngle = 90.0;

/// Größere Lücke = GPS-Aussetzer. Über so etwas hinweg zu mitteln würde
/// einen einzelnen alten Punkt minutenlang gewichten.
const _maxGapSec = 10.0;

/// Darunter gilt das Boot als stehend — Warten vor dem Start, Flaute,
/// Kentern. Zählt weder in die Fahrtzeit noch in den Schnitt.
const _movingKnots = 0.5;

/// Fensterlänge für den Spitzenspeed. 2 s ist das Maß, in dem die
/// Speedsurfing-Szene misst: lang genug gegen GPS-Ausreißer, kurz genug,
/// um eine echte Surfwelle noch zu zeigen.
const _peakWindowSec = 2.0;

/// Darunter ist der GPS-Kurs Rauschen — das Gerät leitet COG aus der
/// Bewegung ab, im Stand dreht er sich frei.
const _cogValidKnots = 1.0;

/// So lange darf eine Wende höchstens dauern. Das ist der Wert, der eine
/// Wende von langsamem Eindrehen trennt.
const _turnMaxSec = 8.0;

/// Sperre nach einer erkannten Wende, damit das Ausschwingen auf dem neuen
/// Bug nicht als zweite Wende zählt.
const _turnLockout = Duration(seconds: 10);

/// Schwelle für die Wendenerkennung, abgeleitet aus dem Wendewinkel des
/// Boots (Winkel ZWISCHEN den beiden Am-Wind-Kursen, Europe: 90°).
///
/// Der Wendewinkel selbst taugt nicht als Schwelle: eine saubere Wende
/// landet genau darauf, und drumherum streut alles — COG-Rauschen, ein
/// asymmetrischer Ausgang, Winddreher zwischen den Schlägen. Mit 90° als
/// Schwelle ginge rund die Hälfte der Wenden verloren. 70 % liegen sicher
/// darunter und immer noch klar über dem Wellensteuern (±15-20°).
/// Der Boden fängt unsinnig kleine Eingaben ab.
double maneuverThresholdDeg(double tackAngleDeg) =>
    max(35.0, tackAngleDeg * 0.7);

/// Kleinste Differenz zweier Kompasskurse in Grad, immer 0..180.
double headingDelta(double a, double b) => ((a - b + 540) % 360 - 180).abs();

class SessionStats {
  /// Meter. Summe der Punktabstände — zählt auch über GPS-Lücken hinweg,
  /// sonst fehlten ganze Streckenteile.
  final double distanceMeters;

  /// Knoten. Höchster über 2 s gemittelter Speed, nicht ein einzelner
  /// GPS-Sample. null, wenn kein volles Fenster zustande kam.
  final double? peakSpeed;

  /// Knoten. Zeitgewichtet über alle Abschnitte in Fahrt — ohne Stillstand
  /// und ohne GPS-Lücken.
  final double? avgMovingSpeed;

  /// Zeit in Fahrt. Gesamtdauer steht in der Session selbst.
  final Duration movingTime;

  /// Erkannte Wenden. Halsen sind bewusst NICHT enthalten: eine Europe
  /// halst je nach Wind durch 40° oder weniger, jede Schwelle, die Wenden
  /// sauber trennt, ist dafür zu hoch. Krängung taugt als Ersatzsignal
  /// nicht — Pumpen auf dem Vorwind erzeugt Krängungswechsel ohne Halse,
  /// und eine Halse geht auch ohne Krängungswechsel.
  final int tacks;

  const SessionStats({
    required this.distanceMeters,
    required this.peakSpeed,
    required this.avgMovingSpeed,
    required this.movingTime,
    required this.tacks,
  });

  static const empty = SessionStats(
    distanceMeters: 0,
    peakSpeed: null,
    avgMovingSpeed: null,
    movingTime: Duration.zero,
    tacks: 0,
  );
}

/// Erwartet [pts] nach Zeit aufsteigend — so liefert es
/// `getPointsForSession` bereits (ORDER BY timestamp ASC).
///
/// [tackAngleDeg] kommt vom Boot der Session, siehe [maneuverThresholdDeg].
SessionStats computeSessionStats(
  List<GpsPointEntity> pts, {
  required double tackAngleDeg,
}) {
  if (pts.length < 2) return SessionStats.empty;

  const geo = Distance();
  final turnDeg = maneuverThresholdDeg(tackAngleDeg);

  double distance = 0;
  double movingSum = 0, movingTime = 0;

  // Peak-Fenster als rollende Summe: die Schleife bleibt O(n), unabhängig
  // davon wie lang das Fenster ist oder wie hoch die Abtastrate wird.
  var winStart = 0;
  double winSum = 0, peak = 0;

  // Referenzpunkt für die Wendenerkennung, gleitend ~_turnMaxSec zurück.
  var refIdx = 0;
  var tacks = 0;
  DateTime? lockedUntil;

  for (var i = 0; i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final dt = b.timestamp.difference(a.timestamp).inMilliseconds / 1000;

    distance += geo(LatLng(a.lat, a.lon), LatLng(b.lat, b.lon));

    if (dt <= 0 || dt > _maxGapSec) {
      // Über eine Lücke hinweg ist weder ein Mittel noch ein Kursvergleich
      // sinnvoll — alle Fenster hinter der Lücke neu aufsetzen.
      winStart = i + 1;
      winSum = 0;
      refIdx = i + 1;
      continue;
    }

    final vMid = (a.sog + b.sog) / 2; // Trapezregel über das Intervall

    // ── Ø fahrend: zeitgewichtet, ohne Stillstand ──────────────────
    if (vMid > _movingKnots) {
      movingSum += vMid * dt;
      movingTime += dt;
    }

    // ── Spitzenspeed über 2 s ──────────────────────────────────────
    winSum += vMid * dt;
    // Fenster so weit schrumpfen, wie es dabei >= _peakWindowSec bleibt
    while (winStart < i) {
      final spanAfter =
          b.timestamp.difference(pts[winStart + 1].timestamp).inMilliseconds /
          1000;
      if (spanAfter < _peakWindowSec) break;
      final firstDt =
          pts[winStart + 1].timestamp
              .difference(pts[winStart].timestamp)
              .inMilliseconds /
          1000;
      winSum -= (pts[winStart].sog + pts[winStart + 1].sog) / 2 * firstDt;
      winStart++;
    }
    final span =
        b.timestamp.difference(pts[winStart].timestamp).inMilliseconds / 1000;
    if (span >= _peakWindowSec) peak = max(peak, winSum / span);

    // ── Wenden ─────────────────────────────────────────────────────
    // Referenz mitziehen, damit sie höchstens _turnMaxSec alt ist. Ein
    // echtes gleitendes Fenster — bei einer Referenz, die nur alle 8 s
    // zurückspringt, fiele jede Wende an der Sprungstelle durch.
    while (refIdx < i &&
        b.timestamp.difference(pts[refIdx].timestamp).inMilliseconds / 1000 >
            _turnMaxSec) {
      refIdx++;
    }

    if (b.sog >= _cogValidKnots) {
      if (lockedUntil != null && b.timestamp.isBefore(lockedUntil)) {
        // Noch in der Sperre — Referenz auf den neuen Bug nachziehen.
        refIdx = i + 1;
      } else if (headingDelta(b.cog, pts[refIdx].cog) > turnDeg) {
        tacks++;
        lockedUntil = b.timestamp.add(_turnLockout);
        refIdx = i + 1;
      }
    }
  }

  return SessionStats(
    distanceMeters: distance,
    peakSpeed: peak > 0 ? peak : null,
    avgMovingSpeed: movingTime > 0 ? movingSum / movingTime : null,
    movingTime: Duration(milliseconds: (movingTime * 1000).round()),
    tacks: tacks,
  );
}
