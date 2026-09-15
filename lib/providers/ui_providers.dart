import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tacktics/data/entities/session.dart';

final windDirectionProvider = NotifierProvider<WindDirectionNotifier, double>(
  WindDirectionNotifier.new,
);

class WindDirectionNotifier extends Notifier<double> {
  @override
  double build() => 0.0; // Startwert

  void set(double degrees) => state = degrees;
}

// Welche Session aktuell angezeigt wird
final selectedSessionProvider =
    NotifierProvider<SelectedSessionNotifier, SessionEntity?>(
      SelectedSessionNotifier.new,
    );

class SelectedSessionNotifier extends Notifier<SessionEntity?> {
  @override
  SessionEntity? build() => null;

  void select(SessionEntity session) => state = session;
  void clear() => state = null;
}

/// Ob der Entwicklermodus freigeschaltet ist.
///
/// EIN Schalter für die ganze App: wer ihn an einer Stelle freischaltet, hat
/// alle dev-gesperrten Elemente frei. Ein Modus ist etwas anderes als eine
/// Sammlung einzeln freizuschaltender Funktionen — sonst müsste man die Geste
/// für jedes gesperrte Element erneut ausführen.
///
/// Der Zähler, der bis zur Freischaltung führt, gehört bewusst NICHT hierher,
/// sondern in den State des jeweiligen Buttons (siehe ShadowIconButton). Wäre
/// er global, würden fünf Tipps auf den einen und fünf auf einen anderen
/// gesperrten Button zusammen freischalten — das ist nicht die Geste.
final devUnlockProvider = NotifierProvider<DevUnlockNotifier, bool>(
  DevUnlockNotifier.new,
);

class DevUnlockNotifier extends Notifier<bool> {
  static const _prefsKey = 'dev_mode_unlocked';

  @override
  bool build() {
    // SharedPreferences ist asynchron, build() ist es nicht. Der Start ist
    // deshalb immer "gesperrt" und kippt, sobald der Wert gelesen ist —
    // beim App-Start blitzt der gesperrte Zustand also kurz auf.
    _restore();
    return false;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey) ?? false;
    // Zwischen Start und Antwort kann der Provider weg sein.
    if (ref.mounted && stored) state = true;
  }

  /// Schaltet frei und merkt es sich über Neustarts hinweg. Ohne das Speichern
  /// wäre die Geste bei jedem App-Start erneut fällig.
  Future<void> unlock() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// Sperrt wieder. Erreichbar über einen langen Druck auf einen Button mit
  /// `devOnly`, solange der Modus offen ist — siehe ShadowIconButton. Ohne
  /// diesen Weg käme man an den Schalter nur noch per adb an die Prefs-Datei.
  Future<void> lock() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

// Ob das SlideMenu offen ist (braucht ExpandedBody zum Schließen)
final isExpandedProvider = NotifierProvider<IsExpandedNotifier, bool>(
  IsExpandedNotifier.new,
);

class IsExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void close() => state = false;
  void setExpanded(bool value) => state = value;
}

enum PathMode { speed, dynamicSpeed, heel }

final pathModeProvider = NotifierProvider<PathModeNotifier, PathMode>(
  PathModeNotifier.new,
);

class PathModeNotifier extends Notifier<PathMode> {
  @override
  PathMode build() => PathMode.speed;

  void next() =>
      state = PathMode.values[(state.index + 1) % PathMode.values.length];
}
