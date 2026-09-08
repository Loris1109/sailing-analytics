import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Der Server hat die Rückmeldung abgelehnt — im Gegensatz zu einem
/// Verbindungsfehler hilft hier kein späterer Versuch, sondern nur eine
/// Änderung an Tabelle oder Policy.
class FeedbackException implements Exception {
  final String message;

  const FeedbackException(this.message);

  @override
  String toString() => 'FeedbackException: $message';
}

class FeedbackService {
  final SupabaseClient supabaseClient;

  const FeedbackService(this.supabaseClient);

  Future<void> _ensureSignedIn() async {
    if (supabaseClient.auth.currentSession == null) {
      await supabaseClient.auth.signInAnonymously();
    }
  }

  /// Schickt eine Rückmeldung direkt an Supabase.
  ///
  /// Bewusst ohne lokale Warteschlange: ohne Verbindung wirft der Aufruf, und
  /// der Dialog lässt den eingegebenen Text stehen, damit man es erneut
  /// versuchen kann. Das Feedback liegt damit nie irgendwo unbemerkt fest.
  ///
  /// `user_id` setzt Postgres selbst über `default auth.uid()` — der Client
  /// schickt sie nicht mit, sonst könnte man sie fälschen.
  /// Session-Angaben hängen nur dran, wenn die Rückmeldung sich auch wirklich
  /// um eine Session dreht — der Dialog fragt das ab.
  ///
  /// Beide sind bewusst freier Text ohne Fremdschlüssel: hochgeladen werden
  /// nur Sessions, die zu einem Training gehören, die meisten liegen also nur
  /// lokal. Ein Constraint würde den Insert dann ablehnen.
  ///
  /// [sessionName] ist das, was beim Lesen im Dashboard sofort etwas sagt,
  /// aber nicht eindeutig ist — er wird als `Training <Datum>` erzeugt.
  /// [sessionId] ist eindeutig und zugleich der Eingabewert des UUIDv5, aus
  /// dem `UploadService` die `upload_id` bildet: wurde die Session je
  /// eingereicht, lässt sich die Upload-Zeile damit wiederfinden.
  Future<void> submit({
    required String message,
    String? contact,
    String? sessionId,
    String? sessionName,
  }) async {
    await _ensureSignedIn();

    try {
      await supabaseClient.from('feedback').insert({
        'message': message,
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        'session_id': ?sessionId,
        'session_name': ?sessionName,
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
      });
    } on PostgrestException catch (e) {
      // Fehlende Spalte, verletzte Policy, kaputter Typ — alles Fälle, die
      // sich nicht dadurch lösen, dass man es gleich nochmal probiert
      throw FeedbackException(e.message);
    }
  }
}
