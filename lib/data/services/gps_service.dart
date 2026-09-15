import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsService {
  // Call this once before starting any stream
  // Returns true if ready, false if user denied
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // GPS is turned off in phone settings
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // user said no
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // User said "never ask again" — send them to settings
      await Geolocator.openAppSettings();
      return false;
    }

    return true; // all good
  }

  // One-time position, useful for showing current location on map
  static Future<Position?> getLastKnownPosition() async {
    final ready = await requestPermission();
    if (!ready) return null;
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
            // steht in jedem aufgezeichneten Punkt cog = 0, und die
            // Wendenerkennung hat nichts, woran sie arbeiten kann.
            //
            // true nimmt stattdessen den LocationManager, also das rohe GNSS —
            // das, was ein Segler ohnehin will: ungefilterte Fixe statt einer
            // für Landverkehr optimierten Schätzung aus Sensorfusion und WLAN.
            //
            // Die Zeile war zwischen dem 17.06. und dem 23.07.2026 schon
            // einmal da. Seit sie in einem Aufräum-Commit herausfiel, ist der
            // COG aller Aufzeichnungen 0.
            forceLocationManager: true,
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
