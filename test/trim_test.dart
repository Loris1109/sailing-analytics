// test/trim_test.dart
// TrimRange ist rein — der Test braucht weder DB noch Widget.

import 'package:flutter_test/flutter_test.dart';
import 'package:tacktics/data/entities/gps_point.dart';
import 'package:tacktics/data/services/trim.dart';

final _t0 = DateTime(2026, 9, 9, 12);

DateTime _at(int sec) => _t0.add(Duration(seconds: sec));

/// Ein Punkt je Sekunde, 0 bis einschließlich [lastSec].
List<GpsPointEntity> _points(int lastSec) => [
  for (var s = 0; s <= lastSec; s++)
    GpsPointEntity(
      id: '$s',
      sessionId: 'test',
      timestamp: _at(s),
      lat: 54.0,
      lon: 10.0,
      sog: 4.0,
      cog: 0,
      heel: 0,
      pitch: 0,
      magHeading: 0,
      accuracy: 3,
    ),
];

void main() {
  test('schneidet auf die Spanne, Grenzen eingeschlossen', () {
    final cut = TrimRange(_at(10), _at(20)).apply(_points(100));

    expect(cut.length, 11); // 10..20
    expect(cut.first.timestamp, _at(10));
    expect(cut.last.timestamp, _at(20));
  });

  test('eine Spanne über die ganze Session gibt die Liste unverändert zurück', () {
    final points = _points(100);
    // identical, nicht nur gleich: der häufigste Fall soll keine Kopie von
    // zehntausenden Punkten erzeugen.
    expect(identical(TrimRange(_at(0), _at(100)).apply(points), points), isTrue);
    expect(
      identical(TrimRange(_at(-10), _at(999)).apply(points), points),
      isTrue,
    );
  });

  test('eine Spanne neben der Session ergibt nichts', () {
    expect(TrimRange(_at(200), _at(300)).apply(_points(100)), isEmpty);
  });

  test('Grenzen zwischen zwei Punkten runden nach innen', () {
    final points = _points(100);
    final cut = TrimRange(
      _at(10).add(const Duration(milliseconds: 500)),
      _at(20).add(const Duration(milliseconds: 500)),
    ).apply(points);

    // 10 liegt vor dem Beginn und fällt raus, 20 liegt davor und bleibt.
    expect(cut.first.timestamp, _at(11));
    expect(cut.last.timestamp, _at(20));
  });

  test('doppelte Zeitstempel fallen vollständig in den Ausschnitt', () {
    // Kam im Wassertest auf jedem elften Punkt vor.
    final points = [..._points(5), ..._points(5)]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final cut = TrimRange(_at(2), _at(3)).apply(points);

    expect(cut.length, 4); // zweimal 2 s, zweimal 3 s
  });

  test('leere Punktliste bleibt leer', () {
    expect(TrimRange(_at(0), _at(10)).apply([]), isEmpty);
  });

  test('wertgleiche Spannen sind gleich', () {
    expect(TrimRange(_at(0), _at(10)), TrimRange(_at(0), _at(10)));
    expect(
      TrimRange(_at(0), _at(10)).hashCode,
      TrimRange(_at(0), _at(10)).hashCode,
    );
    expect(TrimRange(_at(0), _at(10)) == TrimRange(_at(0), _at(11)), isFalse);
  });

  test('contains schließt beide Ränder ein', () {
    final range = TrimRange(_at(10), _at(20));

    expect(range.contains(_at(9)), isFalse);
    expect(range.contains(_at(10)), isTrue);
    expect(range.contains(_at(20)), isTrue);
    expect(range.contains(_at(21)), isFalse);
  });
}
