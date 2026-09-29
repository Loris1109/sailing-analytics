// lib/data/services/map_tiles.dart
// Woher die Kartenkacheln kommen. Keine Logik, nur die Adresse — damit
// Token und Stil an genau einer Stelle stehen und nicht im Widget.

/// Konfiguration der Kartenquelle.
///
/// Token und Stil kommen über `--dart-define` herein, nicht aus dem Quelltext:
/// das Repository liegt öffentlich auf GitHub, und Scraper durchsuchen es
/// gezielt nach solchen Zeichenketten. Aus einem fertigen APK ist der Token
/// trotzdem herauszulesen — das ist bei jedem Kartenclient so und lässt sich
/// nicht verhindern. Der Punkt ist nur, ihn nicht zu verschenken.
///
/// Bauen:
/// ```
/// flutter run --dart-define=MAPBOX_TOKEN=pk.…
/// flutter build appbundle --release --dart-define=MAPBOX_TOKEN=pk.…
/// ```
class MapTiles {
  /// Öffentlicher Mapbox-Token (`pk.…`). NIEMALS ein `sk.`-Token: der darf
  /// das Konto verwalten und gehört nie in einen Client.
  static const token = String.fromEnvironment('MAPBOX_TOKEN');

  /// `benutzername/stil-id`, wie Mapbox Studio sie unter „Share" anzeigt.
  ///
  /// Voreinstellung ist der Outdoor-Stil: er zeichnet Wasser, Uferlinie und
  /// Gelände deutlich, statt wie die Straßenstile Autobahnen zu betonen.
  /// Ein eigener Stil aus Studio kommt hier ohne Codeänderung rein.
  static const style = String.fromEnvironment(
    'MAPBOX_STYLE',
    defaultValue: 'mapbox/outdoors-v12',
  );

  /// Ob überhaupt eine Kartenquelle da ist. Ohne Token zeigt die Karte einen
  /// Hinweis statt grauer Kacheln — ein leeres Feld sähe aus wie ein Fehler
  /// im Kartenmaterial, nicht wie eine fehlende Einstellung beim Bauen.
  static bool get isConfigured => token.isNotEmpty;

  /// 512er Kacheln, nicht 256er: sie decken die vierfache Fläche ab und
  /// kosten damit ein Viertel der Anfragen. Mapbox rechnet pro Anfrage ab,
  /// unabhängig von der Kachelgröße. Dafür muss der TileLayer `tileSize: 512`
  /// und `zoomOffset: -1` setzen — sonst zeigt die Karte die falsche
  /// Zoomstufe.
  static String get urlTemplate =>
      'https://api.mapbox.com/styles/v1/$style/tiles/512/{z}/{x}/{y}@2x'
      '?access_token=$token';

  static const attributionMapbox = 'https://www.mapbox.com/about/maps/';
  static const attributionOsm = 'https://www.openstreetmap.org/copyright';
  static const improveMap = 'https://apps.mapbox.com/feedback/';
}
