// lib/data/services/session_stats.dart
// Alle Kennzahlen einer abgeschlossenen Session, linear über die Punktliste:
// ein Vorlauf für die COG-Glättung, dann ein Durchlauf für alles andere.
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
///    verlangt eine Bestätigung des neuen Kurses (_turnConfirmSec). Ohne
///    beides zählte jedes Losfahren nach einer Flaute und jeder einzelne
///    COG-Ausreißer als Wende.
/// 3: Kurs wird aus den Positionen abgeleitet, wenn das COG-Feld der Session
///    leer geblieben ist (siehe [_storedCogIsDead]).
const sessionStatsVersion = 3;

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
/// Bug nicht als zweite Wende zählt. Gerechnet ab dem BEGINN der Wende,
/// nicht ab ihrer Bestätigung — sonst käme _turnConfirmSec obendrauf.
const _turnLockout = Duration(seconds: 10);

/// So lange muss der neue Kurs halten, bevor eine Kursänderung als Wende
/// zählt. Ohne diese Bestätigung genügt ein EINZELNER Sample: Multipath am
/// Mast, ein Fix ohne Bearing, ein Sprung beim Beschleunigen — alles sieht
/// für einen Punkt lang aus wie eine Wende. Eine echte Wende hält den neuen
/// Bug danach viele Sekunden, ein Ausreißer fällt sofort zurück.
const _turnConfirmSec = 2.0;

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

/// Fensterlänge für die COG-Glättung (zentriert, also ±die Hälfte).
///
/// Ein einzelner Sample taugt nicht als Kursangabe: GPS-COG springt bei
/// Multipath (Mast, Baum, Steg) und beim Beschleunigen um zweistellige
/// Beträge, und ein Fix ohne Bearing kommt als 0° herein. Die Wendenerkennung
/// vergleicht zwei Kurse — geglättet werden muss deshalb BEIDEN Enden, sonst
/// wandert derselbe Ausreißer nur von der einen Seite des Vergleichs auf die
/// andere.
const _cogSmoothSec = 2.0;

/// Mindestversatz, aus dem ein Kurs abgeleitet wird. Darunter bestimmt das
/// GPS-Rauschen die Richtung: bei 5 m Genauigkeit ist die Peilung über 1 m
/// Versatz praktisch zufällig, über 3 m dagegen brauchbar.
const _cogDeriveMinMeters = 3.0;

/// So viele Punkte in Fahrt müssen es mindestens sein, bevor [_storedCogIsDead]
/// ein Urteil fällt. Bei einer Handvoll Punkte ist "alle exakt 0" noch Zufall.
const _cogDeadMinSamples = 20;

/// True, wenn das COG-Feld dieser Session nie gefüllt wurde.
///
/// Geprüft wird pro SESSION, nicht pro Punkt — denn 0° ist ein gültiger Kurs,
/// nämlich Nord. Ein einzelner Punkt mit 0 sagt gar nichts. Aber dass jeder
/// Punkt in Fahrt auf die Nachkommastelle genau 0.000 trägt, kommt bei einer
/// echten Aufzeichnung nicht vor: schon Wellensteuern streut um ein paar Grad.
///
/// Hintergrund: Auf Android füllt geolocator das Feld nur, wenn die Plattform
/// einen Bearing meldet, sonst bleibt es 0.0 — siehe `forceLocationManager`
/// in gps_service.dart. Wochenlang stand deshalb in jedem Punkt 0.
///
/// Der Preis eines Fehlurteils ist klein: läge wirklich eine Session vor, die
/// durchgehend exakt nach Norden fährt, ergäbe die Ableitung ebenfalls Nord.
bool _storedCogIsDead(List<GpsPointEntity> pts) {
  var moving = 0;
  for (final p in pts) {
    if (p.sog < _cogValidKnots) continue;
    if (p.cog != 0) return false;
    moving++;
  }
  return moving >= _cogDeadMinSamples;
}

/// Kurs über Grund je Punkt, aus den Positionen gerechnet.
///
/// Für jeden Punkt wird die Peilung des Streckenabschnitts genommen, auf dem
/// er liegt: vom letzten Stützpunkt bis dorthin, wo das Boot [_cogDeriveMinMeters]
/// weiter ist. Alle Punkte dazwischen erben die Peilung dieses Abschnitts —
/// auch rückwirkend, sobald er fertig ist. Das geht, weil hier eine bereits
/// abgeschlossene Session gerechnet wird und die Zukunft mit auf dem Tisch
/// liegt; live wäre dieser Kurs erst Sekunden später bekannt.
List<double> _deriveCog(List<GpsPointEntity> pts) {
  const geo = Distance();
  final out = List<double>.filled(pts.length, 0);
  if (pts.length < 2) return out;

  var anchor = 0;
  double current = 0;

  for (var i = 1; i < pts.length; i++) {
    final from = LatLng(pts[anchor].lat, pts[anchor].lon);
    final to = LatLng(pts[i].lat, pts[i].lon);

    if (geo(from, to) >= _cogDeriveMinMeters) {
      current = (geo.bearing(from, to) + 360) % 360;
      // Den fertigen Abschnitt rückwirkend an seine Punkte verteilen. Jeder
      // Index wird dabei genau einmal beschrieben, anchor läuft nur vorwärts —
      // die verschachtelte Schleife bleibt in Summe O(n).
      for (var k = anchor + 1; k <= i; k++) {
        out[k] = current;
      }
      anchor = i;
    } else {
      // Noch kein voller Abschnitt: vorläufig den letzten Kurs halten. Wird
      // überschrieben, sobald der Abschnitt zustande kommt.
      out[i] = current;
    }
  }

  // Der erste Punkt hat keinen Abschnitt vor sich.
  out[0] = out[1];
  return out;
}

/// Zirkulär gemittelter Kurs je Punkt.
///
/// Zirkulär heißt: über Einheitsvektoren, nicht über die Gradzahlen. Das
/// arithmetische Mittel aus 350° und 10° wäre 180° — genau der Gegenkurs.
///
/// Punkte ohne brauchbaren COG (zu langsam, siehe [_cogValidKnots]) gehen
/// nicht ein; ist das Fenster danach leer, bleibt der Rohwert stehen. Er wird
/// dann ohnehin nicht ausgewertet.
///
/// [raw] kommt entweder aus dem COG-Feld oder aus [_deriveCog] — die Glättung
/// behandelt beide gleich, damit die Wendenerkennung nur einen Pfad kennt.
List<double> _smoothedCog(List<GpsPointEntity> pts, List<double> raw) {
  final out = List<double>.filled(pts.length, 0);
  const half = _cogSmoothSec / 2;

  // Zwei Zeiger über die nach Zeit sortierte Liste — jeder Punkt wird genau
  // einmal addiert und einmal abgezogen, das Ganze bleibt O(n).
  var lo = 0, hi = 0;
  double sumSin = 0, sumCos = 0;
  var n = 0;

  void addAt(int j) {
    if (pts[j].sog < _cogValidKnots) return;
    final rad = raw[j] * pi / 180;
    sumSin += sin(rad);
    sumCos += cos(rad);
    n++;
  }

  void removeAt(int j) {
    if (pts[j].sog < _cogValidKnots) return;
    final rad = raw[j] * pi / 180;
    sumSin -= sin(rad);
    sumCos -= cos(rad);
    n--;
  }

  for (var i = 0; i < pts.length; i++) {
    final t = pts[i].timestamp;
    while (hi < pts.length &&
        pts[hi].timestamp.difference(t).inMilliseconds / 1000 <= half) {
      addAt(hi++);
    }
    while (lo < hi &&
        t.difference(pts[lo].timestamp).inMilliseconds / 1000 > half) {
      removeAt(lo++);
    }
    out[i] = n == 0
        ? raw[i]
        : (atan2(sumSin, sumCos) * 180 / pi + 360) % 360;
  }
  return out;
}

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

  // Kursquelle wählen: das aufgezeichnete COG-Feld, solange es etwas enthält,
  // sonst aus den Positionen abgeleitet. Ein echter COG ist vorzuziehen — er
  // kommt aus der Doppler-Messung des GNSS-Chips, gilt für den Moment des Fixes
  // und schleppt keine Verzögerung mit. Die Ableitung ist der Ersatz für den
  // Fall, dass die Plattform gar nichts geliefert hat.
  final rawCog = _storedCogIsDead(pts)
      ? _deriveCog(pts)
      : [for (final p in pts) p.cog];

  // Geglättete Kurse für die Wendenerkennung. Eigener Vorlauf, weil die
  // Glättung zentriert ist und damit auch Punkte HINTER dem aktuellen
  // braucht — in der Hauptschleife wäre sie nicht zu haben. Bleibt O(n).
  final cog = _smoothedCog(pts, rawCog);

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

  // Laufender Wendekandidat: der Kurs, von dem aus die Änderung begann, und
  // wann sie begann. Wird bestätigt oder verworfen, siehe _turnConfirmSec.
  double? pendingFromCog;
  DateTime? pendingSince;

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
      // Ein Kandidat über die Lücke hinweg wäre nicht mehr belegbar: was
      // dazwischen passiert ist, steht nirgends.
      pendingFromCog = null;
      pendingSince = null;
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
    //
    // Zweite Bedingung: Punkte ohne brauchbaren COG überspringen. Das Gerät
    // leitet den Kurs aus der Bewegung ab, im Stand dreht er frei. Ohne
    // diese Prüfung zeigt die Referenz nach jeder Flaute, jedem Warten vor
    // dem Start und jeder Kenterung auf Rauschen — und das Losfahren danach
    // zählt als Wende, egal in welche Richtung es geht.
    while (refIdx < i &&
        (b.timestamp.difference(pts[refIdx].timestamp).inMilliseconds / 1000 >
                _turnMaxSec ||
            pts[refIdx].sog < _cogValidKnots)) {
      refIdx++;
    }

    if (b.sog >= _cogValidKnots) {
      if (lockedUntil != null && b.timestamp.isBefore(lockedUntil)) {
        // Noch in der Sperre — Referenz auf den neuen Bug nachziehen.
        refIdx = i + 1;
        pendingFromCog = null;
        pendingSince = null;
      } else if (pendingSince != null) {
        // Kandidat läuft. Gegen den eingefrorenen Ausgangskurs prüfen, nicht
        // gegen die Referenz: die rückt während der Wende in den Bogen hinein
        // und ließe den Kandidaten kurz vor der Bestätigung verschwinden.
        if (headingDelta(cog[i + 1], pendingFromCog!) <= turnDeg) {
          pendingFromCog = null; // zurückgefallen — Ausreißer, keine Wende
          pendingSince = null;
        } else if (b.timestamp.difference(pendingSince).inMilliseconds / 1000 >=
            _turnConfirmSec) {
          tacks++;
          // Sperre ab Beginn der Wende, nicht ab ihrer Bestätigung.
          lockedUntil = pendingSince.add(_turnLockout);
          refIdx = i + 1;
          pendingFromCog = null;
          pendingSince = null;
        }
      } else if (pts[refIdx].sog >= _cogValidKnots &&
          headingDelta(cog[i + 1], cog[refIdx]) > turnDeg) {
        // Noch nicht zählen — erst wenn der neue Kurs hält, siehe oben.
        pendingFromCog = cog[refIdx];
        pendingSince = b.timestamp;
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
