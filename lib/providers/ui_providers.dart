import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/entities/session.dart';

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
