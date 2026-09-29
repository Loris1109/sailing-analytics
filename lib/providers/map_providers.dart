import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path_provider/path_provider.dart';

/// Wie lange eine einmal geladene Kachel aus dem Cache bedient wird.
///
/// Bewusst kurz gehalten. Mapbox regelt das Zwischenspeichern in seinen
/// Bedingungen: ein Cache zur Beschleunigung ist vorgesehen, eine dauerhaft
/// heruntergeladene Offlinekarte ist bei ihnen ein eigenes Produkt. Sieben
/// Tage decken die Woche zwischen zwei Trainings auf demselben Revier ab und
/// bleiben klar im unkritischen Bereich.
///
/// Das ist der Wert, an dem man dreht, wenn die Rechnung zu hoch wird — aber
/// erst, nachdem der Abschnitt in den Bedingungen gelesen ist.
const kTileMaxStale = Duration(days: 7);

/// Obergrenze für den Kachelordner.
///
/// [FileCacheStore] kennt keine Größengrenze; es räumt beim Anlegen nur
/// abgelaufene Einträge weg. Ohne Deckel wächst der Ordner innerhalb der
/// Haltbarkeit unbegrenzt — wer eine Woche lang über die Karte wischt, füllt
/// sonst spürbar Speicher.
const kTileCacheMaxBytes = 150 * 1024 * 1024;

/// Kachelquelle der Karte: derselbe Netzabruf wie sonst, nur mit Cache auf
/// der Platte davor.
///
/// Zwei Dinge fallen dabei ab. Erstens kostet jede Kachel, die zweimal
/// geladen würde, bei Mapbox zweimal Geld — der Cache spart also unmittelbar.
/// Zweitens bleibt die Karte ohne Netz lesbar, statt grau zu werden; auf dem
/// Wasser ist das der Normalfall.
///
/// `null`, wenn sich der Ordner nicht anlegen lässt. Die Karte läuft dann
/// ohne Cache weiter — ein fehlgeschlagener Cache darf nie die Karte kosten.
final tileProviderProvider = FutureProvider<TileProvider?>((ref) async {
  try {
    // Der Cache-Ordner des Systems, nicht der Dokumentenordner: Android darf
    // ihn bei Speichermangel von sich aus leeren. Genau das soll er dürfen.
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/map_tiles');
    await dir.create(recursive: true);

    final store = FileCacheStore(dir.path);

    // Nicht abwarten: die Karte soll nicht auf einen Ordnerdurchlauf warten.
    _pruneIfOversized(dir, store);

    return CachedTileProvider(
      store: store,
      // forceCache: vorhandene Kachel nehmen, ohne beim Server nachzufragen.
      // Kartenkacheln ändern sich praktisch nie, und jede Rückfrage wäre eine
      // abgerechnete Anfrage.
      cachePolicy: CachePolicy.forceCache,
      maxStale: kTileMaxStale,
    );
  } catch (_) {
    return null;
  }
});

/// Wirft den Kachelordner weg, sobald er die Grenze reißt.
///
/// Grob absichtlich: es fliegt alles, nicht das Älteste. Eine Verwaltung nach
/// Zugriffszeit wäre erheblich mehr Aufwand für einen Cache, dessen Verlust
/// nur bedeutet, dass die nächsten Kacheln wieder aus dem Netz kommen.
Future<void> _pruneIfOversized(Directory dir, FileCacheStore store) async {
  try {
    var bytes = 0;
    await for (final entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is! File) continue;
      bytes += await entry.length();
      // Sobald die Grenze fällt, ist die Antwort klar — der Rest des Ordners
      // muss nicht mehr gezählt werden.
      if (bytes > kTileCacheMaxBytes) {
        await store.clean();
        return;
      }
    }
  } catch (_) {
    // Aufräumen ist Kür. Scheitert es, bleibt der Ordner eben groß.
  }
}
