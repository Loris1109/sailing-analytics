// lib/data/services/session_stats.dart
// Alle Kennzahlen einer abgeschlossenen Session in EINEM linearen Durchlauf
// über die Punktliste.
// Rein: kein Flutter, keine DB, keine Provider — direkt unit-testbar.
//
// Gerechnet wird einmal beim Beenden der Session (SessionRepository.
// completeSession), das Ergebnis landet als Spalten in `sessions`. Die UI
// liest nur noch Felder — sie fasst die Punktliste nicht mehr an.

import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:tacktics/data/entities/gps_point.dart';

/// Version des Algorithmus. Hochzählen, sobald sich an der Rechnung unten
/// etwas ändert — Sessions mit kleinerer Version werden beim App-Start
/// nachgerechnet (SessionRepository.recomputeOutdatedStats).
///
/// Auch hochzählen, wenn sich eine der Konstanten ändert: die Werte in der
/// DB sind eingefroren und wissen nichts davon.
/// 2: Wendenerkennung prüft den Referenzpunkt auf brauchbaren COG und
///    verlangt eine Bestätigung des neuen Kurses. Ohne beides zählte jedes
///    Losfahren nach einer Flaute und jeder COG-Ausreißer als Wende.
/// 3: Kurs wird aus den Positionen abgeleitet, wenn das COG-Feld der Session
///    leer geblieben ist.
///
/// Die Wendenerkennung (samt COG-Glättung und -Ableitung) ist inzwischen
/// wieder draußen — sie lief zu unzuverlässig und ihre Zahl wurde nirgends
/// angezeigt. Bewusst OHNE Hochzählen: an Distanz, Spitzenspeed, Ø fahrend
/// und Fahrtzeit ändert sich dadurch nichts, ein Nachrechnen aller Sessions
/// beim nächsten Start wäre umsonst. Die Spalte `tacks` bleibt mit ihren
/// alten Werten stehen, falls die Erkennung zurückkommt.
const sessionStatsVersion = 3;

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

  const SessionStats({
    required this.distanceMeters,
    required this.peakSpeed,
    required this.avgMovingSpeed,
    required this.movingTime,
  });

  static const empty = SessionStats(
    distanceMeters: 0,
    peakSpeed: null,
    avgMovingSpeed: null,
    movingTime: Duration.zero,
  );
}

/// Erwartet [pts] nach Zeit aufsteigend — so liefert es
/// `getPointsForSession` bereits (ORDER BY timestamp ASC).
SessionStats computeSessionStats(List<GpsPointEntity> pts) {
  if (pts.length < 2) return SessionStats.empty;

  const geo = Distance();

  double distance = 0;
  double movingSum = 0, movingTime = 0;

  // Peak-Fenster als rollende Summe: die Schleife bleibt O(n), unabhängig
  // davon wie lang das Fenster ist oder wie hoch die Abtastrate wird.
  var winStart = 0;
  double winSum = 0, peak = 0;

  for (var i = 0; i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final dt = b.timestamp.difference(a.timestamp).inMilliseconds / 1000;

    distance += geo(LatLng(a.lat, a.lon), LatLng(b.lat, b.lon));

    if (dt <= 0 || dt > _maxGapSec) {
      // Über eine Lücke hinweg zu mitteln ist nicht sinnvoll — das Fenster
      // dahinter neu aufsetzen.
      winStart = i + 1;
      winSum = 0;
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
  }

  return SessionStats(
    distanceMeters: distance,
    peakSpeed: peak > 0 ? peak : null,
    avgMovingSpeed: movingTime > 0 ? movingSum / movingTime : null,
    movingTime: Duration(milliseconds: (movingTime * 1000).round()),
  );
}
