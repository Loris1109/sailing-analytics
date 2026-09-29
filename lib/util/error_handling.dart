// lib/util/error_handling.dart
// Fängt ab, was sonst niemand sieht.
//
// Ohne diese Handler endet eine unbehandelte Ausnahme im Release-Build als
// graue Fläche ohne Text. Für einen Tester ist das von einem Absturz nicht zu
// unterscheiden, und für dich nicht von einem Bedienfehler — beides kommt als
// „die App war einfach weg" zurück.

import 'dart:developer' as dev;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Einmal beim Start aufrufen, vor `runApp`.
///
/// Es gibt drei getrennte Wege, auf denen ein Fehler aus der App kommt, und
/// jeder braucht seine eigene Anmeldung — einer allein fängt die anderen
/// beiden nicht mit.
void installErrorHandlers() {
  // 1. Fehler aus dem Flutter-Framework: build, layout, paint.
  //
  // Die Voreinstellung wird nicht ersetzt, sondern danach noch aufgerufen:
  // im Debug-Build schreibt sie die ausführliche rote Ausgabe in die
  // Konsole, und genau die will man beim Entwickeln behalten.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    dev.log(
      'Flutter-Fehler: ${details.exceptionAsString()}',
      name: 'tacktics',
      error: details.exception,
      stackTrace: details.stack,
    );
    previousOnError?.call(details);
  };

  // 2. Asynchrones außerhalb des Frameworks: ein Future ohne catch, ein
  //    Stream ohne onError. Das Framework sieht davon nichts.
  //
  // `true` heißt „behandelt" — die App läuft weiter, statt beendet zu
  // werden. Für eine Beta ist das die richtige Wahl: ein Fehler beim
  // Hochladen darf keine laufende Aufzeichnung abschießen.
  PlatformDispatcher.instance.onError = (error, stack) {
    dev.log(
      'Unbehandelter Fehler: $error',
      name: 'tacktics',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // 3. Was an der Stelle des kaputtgegangenen Widgets angezeigt wird.
  //
  // Nur im Release: im Debug-Build ist Flutters rote Fläche mit vollem
  // Stacktrace das nützlichere Werkzeug. Wer die Tester-Ansicht sehen will,
  // setzt die Bedingung hier kurzzeitig auf `true`.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => _ErrorPanel(details: details);
  }
}

/// Steht anstelle des Widgets, das gerade gescheitert ist.
///
/// Bewusst ohne Material-Widgets und ohne Theme: dieser Baustein ersetzt
/// etwas, das eben kaputtgegangen ist, und kann dabei an einer Stelle im
/// Baum landen, an der es weder `Theme` noch `Directionality` gibt. Was hier
/// selbst noch scheitert, fällt auf Flutters graue Fläche zurück — also so
/// wenig Voraussetzungen wie möglich.
class _ErrorPanel extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ErrorPanel({required this.details});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF1F2933),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hier ist etwas schiefgelaufen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF2F4F6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              // Stimmt auch dann, wenn die Oberfläche hinüber ist: die Punkte
              // landen einzeln in der Datenbank, sobald sie ankommen.
              'Deine aufgezeichneten Daten sind gespeichert.\n'
              'Schick mir bitte einen Screenshot dieser Meldung.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB9C4CE), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              _shortMessage,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8FA1B0),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Die Fehlermeldung, auf das gekürzt, was auf einen Screenshot passt.
  ///
  /// Der volle Text wäre für einen Tester unlesbar und für die Diagnose
  /// selten nötig — die erste Zeile benennt fast immer die Ursache.
  String get _shortMessage {
    final full = details.exceptionAsString();
    final firstLine = full.split('\n').first.trim();
    return firstLine.length > 200
        ? '${firstLine.substring(0, 200)}…'
        : firstLine;
  }
}
