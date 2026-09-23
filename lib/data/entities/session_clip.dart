import 'package:tacktics/data/database/app_database.dart';
import 'package:tacktics/data/services/trim.dart';

/// Ein benannter Ausschnitt einer Session — "Rennen 1", "Überführung".
///
/// Hält nur die Zeitspanne. Die Punkte dazu entstehen erst beim Anzeigen,
/// siehe [TrimRange.apply] — ein Ausschnitt kostet damit keine Kopie der
/// Aufzeichnung, und er bleibt gültig, solange die Session existiert.
class SessionClipEntity {
  final String id;
  final String sessionId;
  final String name;
  final TrimRange range;

  const SessionClipEntity({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.range,
  });

  factory SessionClipEntity.fromDb(SessionClip row) => SessionClipEntity(
    id: row.id,
    sessionId: row.sessionId,
    name: row.name,
    range: TrimRange(row.startTime, row.endTime),
  );

  Duration get duration => range.end.difference(range.start);
}
