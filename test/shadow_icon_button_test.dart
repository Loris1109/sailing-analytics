// test/shadow_icon_button_test.dart
// Der Button entscheidet zwischen drei Ausgängen — auslösen, zählen,
// ablehnen. Die Reihenfolge dieser Prüfungen ist die Stelle, an der das
// Feature kaputtgeht, ohne dass es auffällt.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/shadow_icon_button.dart';

/// Baut den Button in einer minimalen App — MaterialApp wegen des Overlays,
/// das die Meldungen braucht.
Future<ProviderContainer> _pumpButton(
  WidgetTester tester, {
  required VoidCallback onTap,
  bool enabled = true,
  bool devOnly = false,
  String? blockedMessage,
  String? devBlockedMessage,
  String? devBlockedDetails,
}) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: ShadowIconButton(
            icon: Icons.upload_rounded,
            enabled: enabled,
            devOnly: devOnly,
            blockedMessage: blockedMessage,
            devBlockedMessage: devBlockedMessage,
            devBlockedDetails: devBlockedDetails,
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

Future<void> _tapTimes(WidgetTester tester, int times) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.byType(ShadowIconButton));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('ein freier Button löst ganz normal aus', (tester) async {
    var taps = 0;
    await _pumpButton(tester, onTap: () => taps++);
    await _tapTimes(tester, 1);
    expect(taps, 1);
  });

  testWidgets('inaktiv: kein Auslösen, aber eine Meldung', (tester) async {
    var taps = 0;
    await _pumpButton(
      tester,
      onTap: () => taps++,
      enabled: false,
      blockedMessage: 'Wähle zuerst eine Session aus.',
    );
    await _tapTimes(tester, 1);
    await tester.pump(const Duration(milliseconds: 300));

    expect(taps, 0);
    expect(find.text('Wähle zuerst eine Session aus.'), findsOneWidget);
  });

  group('Entwicklermodus', () {
    testWidgets('zehn Tipps schalten frei, vorher löst nichts aus', (
      tester,
    ) async {
      var taps = 0;
      final container = await _pumpButton(
        tester,
        onTap: () => taps++,
        devOnly: true,
      );

      await _tapTimes(tester, 9);
      expect(container.read(devUnlockProvider), isFalse, reason: 'neun reichen nicht');
      expect(taps, 0, reason: 'gesperrt darf nicht auslösen');

      await _tapTimes(tester, 1);
      await tester.pump();
      expect(container.read(devUnlockProvider), isTrue);
    });

    // ── Die eigentliche Falle ──────────────────────────────────────────
    // Der Upload-Button ist gesperrt UND inaktiv, solange keine Session
    // gewählt ist — und das ist der Normalzustand. Käme die enabled-Prüfung
    // zuerst, würde sie den Tipp schlucken und die Geste wäre nie ausführbar.
    testWidgets('schaltet auch frei, während der Button inaktiv ist', (
      tester,
    ) async {
      var taps = 0;
      final container = await _pumpButton(
        tester,
        onTap: () => taps++,
        devOnly: true,
        enabled: false,
        blockedMessage: 'Wähle zuerst eine Session aus.',
      );

      await _tapTimes(tester, 10);
      await tester.pump();

      expect(container.read(devUnlockProvider), isTrue);
      expect(taps, 0);
    });

    testWidgets('nach dem Freischalten gilt wieder enabled', (tester) async {
      var taps = 0;
      final container = await _pumpButton(
        tester,
        onTap: () => taps++,
        devOnly: true,
      );

      await _tapTimes(tester, 10);
      await tester.pump();
      expect(container.read(devUnlockProvider), isTrue);

      await _tapTimes(tester, 1);
      expect(taps, 1, reason: 'freigeschaltet und aktiv -> löst aus');
    });

    testWidgets('gesperrt erklärt sich beim ersten Tipp', (tester) async {
      var taps = 0;
      await _pumpButton(
        tester,
        onTap: () => taps++,
        devOnly: true,
        devBlockedMessage: 'Kommt in einer der nächsten Versionen.',
      );

      await _tapTimes(tester, 1);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kommt in einer der nächsten Versionen.'), findsOneWidget);
      expect(taps, 0);
    });

    testWidgets('die Erklärung wiederholt sich nicht bei jedem Tipp', (
      tester,
    ) async {
      // Sonst stapeln sich beim Freischalten zehn Meldungen übereinander.
      await _pumpButton(
        tester,
        onTap: () {},
        devOnly: true,
        devBlockedMessage: 'Kommt in einer der nächsten Versionen.',
      );

      await _tapTimes(tester, 4);
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Kommt in einer der nächsten Versionen.'),
        findsOneWidget,
        reason: 'vier schnelle Tipps, eine Meldung',
      );
    });

    testWidgets('ein Tipp auf die Snackbar zeigt den vollen Text', (
      tester,
    ) async {
      const long =
          'Ein Erklärtext, der für zwei Zeilen viel zu lang ist und deshalb '
          'in der Snackbar abgeschnitten würde — hier steht er vollständig.';
      await _pumpButton(
        tester,
        onTap: () {},
        devOnly: true,
        devBlockedMessage: 'Noch nicht verfügbar — tippen für Details',
        devBlockedDetails: long,
      );

      await _tapTimes(tester, 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(long), findsNothing, reason: 'erst nach dem Tipp');

      await tester.tap(find.text('Noch nicht verfügbar — tippen für Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(long), findsOneWidget);
    });

    testWidgets('ohne Details bleibt die Snackbar ein reiner Hinweis', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        onTap: () {},
        devOnly: true,
        devBlockedMessage: 'Noch nicht verfügbar',
      );

      await _tapTimes(tester, 1);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Noch nicht verfügbar'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNothing);
    });

    // Der Grund für die Snackbar statt eines selbst aufgehenden Dialogs: sie
    // sitzt oben, verdeckt den Button nicht und muss nicht weggeklickt werden.
    // Ein Dialog würde den Tipp-Timeout überdauern und die Geste blockieren.
    testWidgets('die Freischaltung läuft trotz sichtbarer Snackbar weiter', (
      tester,
    ) async {
      final container = await _pumpButton(
        tester,
        onTap: () {},
        devOnly: true,
        devBlockedMessage: 'Noch nicht verfügbar — tippen für Details',
        devBlockedDetails: 'Langer Text.',
      );

      await _tapTimes(tester, 10);
      await tester.pump();

      expect(container.read(devUnlockProvider), isTrue);
    });

    testWidgets('langer Druck sperrt wieder', (tester) async {
      var taps = 0;
      final container = await _pumpButton(
        tester,
        onTap: () => taps++,
        devOnly: true,
      );

      await _tapTimes(tester, 10);
      await tester.pump();
      expect(container.read(devUnlockProvider), isTrue);

      // Erst belegen, dass überhaupt etwas gespeichert wurde — sonst wäre die
      // Prüfung nach dem Sperren unten grün, ohne etwas zu beweisen.
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getBool('dev_mode_unlocked'), isTrue);

      await tester.longPress(find.byType(ShadowIconButton));
      await tester.pump();
      expect(container.read(devUnlockProvider), isFalse);

      await prefs.reload();
      expect(prefs.getBool('dev_mode_unlocked'), isNull);
    });

    testWidgets('langer Druck auf einen gesperrten Button tut nichts', (
      tester,
    ) async {
      // Täte er etwas, wäre die Sperre nicht mehr versteckt.
      var taps = 0;
      final container = await _pumpButton(
        tester,
        onTap: () => taps++,
        devOnly: true,
      );

      await tester.longPress(find.byType(ShadowIconButton));
      await tester.pump();

      expect(container.read(devUnlockProvider), isFalse);
      expect(taps, 0);
    });

    testWidgets('ein bereits freigeschalteter Modus wird geladen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'dev_mode_unlocked': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var taps = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ShadowIconButton(
                icon: Icons.upload_rounded,
                devOnly: true,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      // Der gespeicherte Wert kommt asynchron — ein Frame reicht dafür nicht.
      await tester.pump();
      await tester.pump();

      expect(container.read(devUnlockProvider), isTrue);
      await _tapTimes(tester, 1);
      expect(taps, 1, reason: 'kein erneutes Freischalten nötig');
    });
  });
}
