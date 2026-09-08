import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/services/feedback_service.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';

// Ablauf: schreiben → senden → fertig. Schlägt das Senden fehl, geht es
// zurück auf "schreiben" — der Text bleibt stehen, weil es keine lokale
// Warteschlange gibt und die Rückmeldung sonst verloren wäre.
enum _FeedbackStep { compose, sending, done }

class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _messageController = TextEditingController();
  final _contactController = TextEditingController();
  _FeedbackStep _step = _FeedbackStep.compose;
  String? _error;

  /// Vorbelegt, weil eine überflüssig angehängte Session bloß Rauschen ist,
  /// eine fehlende bei einer Session-Rückmeldung aber nicht mehr zu
  /// rekonstruieren. Wer über etwas anderes schreibt, hakt sie ab.
  bool _attachSession = true;

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Bitte etwas schreiben');
      return;
    }

    setState(() {
      _step = _FeedbackStep.sending;
      _error = null;
    });

    final session = ref.read(selectedSessionProvider);

    try {
      await ref
          .read(feedbackServiceProvider)
          .submit(
            message: message,
            contact: _contactController.text.trim(),
            sessionId: _attachSession ? session?.id : null,
            sessionName: _attachSession ? session?.name : null,
          );
      if (!mounted) return;
      setState(() => _step = _FeedbackStep.done);
    } on FeedbackException catch (e) {
      // Nicht als Verbindungsproblem ausgeben — sonst versucht man es
      // endlos erneut, während in Wahrheit die Tabelle nicht passt
      debugPrint('submitFeedback rejected: ${e.message}');
      if (!mounted) return;
      setState(() {
        _step = _FeedbackStep.compose;
        _error = 'Vom Server abgelehnt: ${e.message}';
      });
    } catch (e) {
      debugPrint('submitFeedback failed: $e');
      if (!mounted) return;
      setState(() {
        _step = _FeedbackStep.compose;
        _error = 'Keine Verbindung — bitte später erneut versuchen';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step != _FeedbackStep.sending,
      child: AlertDialog(
        title: const Text('Feedback'),
        content: _buildContent(),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _FeedbackStep.compose:
        final session = ref.watch(selectedSessionProvider);
        // Scrollbar, weil bei offener Tastatur sonst zwei Textfelder plus
        // Checkbox aus dem Dialog laufen
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _messageController,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Was ist dir aufgefallen?',
                  hintText: 'Fehler, Wunsch, Beobachtung auf dem Wasser …',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contactController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-Mail (optional)',
                  helperText: 'Nur falls ich nachfragen darf',
                ),
              ),
              // Nur anbieten, wenn es überhaupt etwas anzuhängen gibt — nicht
              // jede Rückmeldung dreht sich um eine Session
              if (session != null)
                CheckboxListTile(
                  value: _attachSession,
                  onChanged: (v) => setState(() => _attachSession = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: Text(
                    'Session „${session.name}" mitschicken',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Mitgeschickt werden außerdem Betriebssystem und Version.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        );

      case _FeedbackStep.sending:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Flexible(child: Text('Wird gesendet …')),
          ],
        );

      case _FeedbackStep.done:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 12),
            Flexible(child: Text('Danke — ist angekommen')),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_step) {
      case _FeedbackStep.compose:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(onPressed: _send, child: const Text('Senden')),
        ];

      case _FeedbackStep.sending:
        return const []; // keine Aktionen während der Netz-Operation

      case _FeedbackStep.done:
        return [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ];
    }
  }
}
