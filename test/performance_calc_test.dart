import 'package:flutter_test/flutter_test.dart';
import 'package:sailing_analytics/data/services/performance_calc.dart';

void main() {
  group('twa', () {
    test('einfacher Fall: Wind 180, Kurs 135 → +45 (Wind von Steuerbord)', () {
      expect(twa(135, 180), closeTo(45, 0.001));
    });

    test('Wind von Backbord ist negativ', () {
      expect(twa(225, 180), closeTo(-45, 0.001));
    });

    test('Normalisierung über die 0°-Grenze: COG 350, Wind 10 → +20', () {
      expect(twa(350, 10), closeTo(20, 0.001));
    });

    test('Normalisierung andersherum: COG 10, Wind 350 → -20', () {
      expect(twa(10, 350), closeTo(-20, 0.001));
    });

    test('direkt vor dem Wind → ±180', () {
      expect(twa(0, 180).abs(), closeTo(180, 0.001));
    });

    test('direkt gegen den Wind → 0', () {
      expect(twa(180, 180), closeTo(0, 0.001));
    });
  });

  group('vmg', () {
    test('gegen den Wind = volle SOG', () {
      expect(vmg(5, 0), closeTo(5, 0.001));
    });

    test('halber Wind = 0', () {
      expect(vmg(5, 90), closeTo(0, 0.001));
    });

    test('vor dem Wind = negative SOG', () {
      expect(vmg(5, 180), closeTo(-5, 0.001));
    });

    test('45° am Wind: cos(45°) ≈ 0.707', () {
      expect(vmg(6, 45), closeTo(4.243, 0.001));
    });

    test('Vorzeichen des TWA ist für VMG egal', () {
      expect(vmg(6, -45), closeTo(vmg(6, 45), 0.001));
    });
  });
}
