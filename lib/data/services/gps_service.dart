import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Warum der Standort nicht zu haben ist — oder dass er es ist.
///
/// Vier Fälle statt eines `bool`, weil sie vier verschiedene Antworten
/// verlangen: einmal Weitermachen, einmal „schalt das GPS ein", einmal
/// „erlaub es beim nächsten Mal", einmal „das geht nur noch über die
/// Einstellungen". Ein gemeinsames `false` ließ die Oberfläche raten — und
/// sie hat dann gar nichts gesagt.
enum LocationReadiness { ready, serviceDisabled, denied, deniedForever }

class GpsService {
  /// Prüft Gerätedienst und Freigabe und fragt, wenn nötig, nach.
  ///
  /// Öffnet bewusst NICHT von sich aus die Systemeinstellungen. Ein
  /// Funktionsaufruf, der den Nutzer wortlos aus der App wirft, ist keine
  /// Prüfung mehr — der Weg dorthin gehört in die Oberfläche, wo daneben
  /// stehen kann, warum.
  static Future<LocationReadiness> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationReadiness.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.denied => LocationReadiness.denied,
      LocationPermission.deniedForever => LocationReadiness.deniedForever,
      _ => LocationReadiness.ready,
    };
  }

  /// Bringt den Nutzer zu den App-Einstellungen. Gehört zum Fall
  /// [LocationReadiness.deniedForever], den die App selbst nicht mehr
  /// auflösen kann.
  static Future<void> openSettings() => Geolocator.openAppSettings();

  /// Fragt die Freigabe für die Benachrichtigung des Vordergrunddienstes an —
  /// und hält nichts auf, wenn sie ausbleibt.
  ///
  /// Ab Android 13 braucht es sie, damit die Anzeige überhaupt erscheint. Der
  /// Dienst selbst läuft auch ohne sie weiter, die Aufzeichnung ist also nicht
  /// betroffen — nur sieht dann niemand, dass sie läuft. Eine Aufzeichnung
  /// deswegen zu verweigern wäre die falsche Abwägung.
  ///
  /// Nur auf Android: auf iOS gibt es keinen Vordergrunddienst und der Dialog
  /// käme grundlos.
  static Future<void> ensureNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Permission.notification.request();
    } catch (_) {
      // Auch ein Fehlschlag darf die Aufzeichnung nicht aufhalten.
    }
  }

  // One-time position, useful for showing current location on map
  static Future<Position?> getLastKnownPosition() async {
    if (await ensureReady() != LocationReadiness.ready) return null;
    return Geolocator.getLastKnownPosition();
  }

  static Stream<Position> getStream() {
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
            intervalDuration: const Duration(milliseconds: 250),
            // NICHT entfernen — das ist keine Debug-Einstellung.
            //
            // false (der Standard) bedeutet FusedLocationProvider aus den
            // Google Play Services. Der liefert Position und Geschwindigkeit,
            // aber KEINEN Bearing: `Location.hasBearing()` ist dort dauerhaft
            // false, und geolocator gibt den Kurs dann als 0.0 zurück. Damit
            // steht in jedem aufgezeichneten Punkt cog = 0 — im GPX-Export
            // und im Upload landet dann eine Spalte aus Nullen.
            //
            // true nimmt stattdessen den LocationManager, also das rohe GNSS —
            // das, was ein Segler ohnehin will: ungefilterte Fixe statt einer
            // für Landverkehr optimierten Schätzung aus Sensorfusion und WLAN.
            //
            // Die Zeile war zwischen dem 17.06. und dem 23.07.2026 schon
            // einmal da. Seit sie in einem Aufräum-Commit herausfiel, ist der
            // COG aller Aufzeichnungen 0.
            forceLocationManager: true,

            // Macht den Standortdienst zum VORDERGRUNDDIENST. Ohne diese
            // Angabe läuft er als gewöhnlicher Hintergrundprozess, und
            // Android drosselt ihn, sobald der Bildschirm aus ist oder die
            // App nicht mehr vorn liegt — bei einer sechsstündigen Regatta
            // hört die Aufzeichnung dann irgendwo unterwegs auf.
            //
            // Der Wakelock kommt mit: ohne ihn darf das Gerät schlafen und
            // liefert die gesammelten Fixe erst beim Aufwachen im Block
            // nach. Für eine Spur ist das dasselbe wie gar nichts — die
            // Abtastrate bricht zusammen und die Zeitstempel häufen sich.
            // Das kostet Akku, und zwar bewusst: das Gerät liegt beim
            // Segeln ohnehin an Deck und tut genau diese eine Aufgabe.
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Tacktics zeichnet auf',
              notificationText: 'Position, Kurs und Krängung werden mitgeschrieben.',
              notificationChannelName: 'Aufzeichnung',
              // Silhouette, keine Vollfarbgrafik: Android benutzt für das
              // kleine Symbol nur den Alphakanal. Das Launcher-Icon käme
              // dort als weißer Klecks an.
              notificationIcon: AndroidResource(
                name: 'ic_launcher_monochrome',
                defType: 'drawable',
              ),
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            pauseLocationUpdatesAutomatically: false,
            activityType: ActivityType.otherNavigation,
          );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
