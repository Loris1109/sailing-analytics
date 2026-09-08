import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/entities/session.dart';
import 'package:sailing_analytics/data/services/upload_service.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';

// Ablauf: Code eingeben → auflösen → bestätigen → hochladen → fertig.
// Jeder Zustand ist ein eigenes Stück UI, die Handler schalten weiter.
enum _UploadStep { enterCode, resolving, confirm, uploading, done }

class UploadDialog extends ConsumerStatefulWidget {
  final SessionEntity session;
  const UploadDialog({super.key, required this.session});

  @override
  ConsumerState<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<UploadDialog> {
  final _codeController = TextEditingController();
  _UploadStep _step = _UploadStep.enterCode;
  ResolvedTraining? _training;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Bitte einen Code eingeben');
      return;
    }
    setState(() {
      _step = _UploadStep.resolving;
      _error = null;
    });

    try {
      final training = await ref
          .read(uploadServiceProvider)
          .resolveTraining(code);
      if (!mounted) return;

      if (training == null) {
        setState(() {
          _step = _UploadStep.enterCode;
          _error = 'Code unbekannt — bitte prüfen';
        });
      } else if (!training.isOpen) {
        setState(() {
          _step = _UploadStep.enterCode;
          _error = 'Dieses Training ist bereits geschlossen';
        });
      } else {
        setState(() {
          _training = training;
          _step = _UploadStep.confirm;
        });
      }
    } catch (e) {
      debugPrint('resolveTraining failed: $e');
      if (!mounted) return;
      setState(() {
        _step = _UploadStep.enterCode;
        _error = 'Keine Verbindung — bitte später erneut versuchen';
      });
    }
  }

  Future<void> _upload() async {
    final training = _training;
    if (training == null) return;
    setState(() {
      _step = _UploadStep.uploading;
      _error = null;
    });

    try {
      debugPrint('📤 Starting upload for session: ${widget.session.id}');

      final points = await ref
          .read(sessionRepositoryProvider)
          .getPointsForSession(widget.session.id);
      debugPrint('📊 Loaded ${points.length} GPS points');

      if (points.isEmpty) {
        if (!mounted) return;
        setState(() {
          _step = _UploadStep.confirm;
          _error = 'Diese Session hat keine GPS-Punkte';
        });
        return;
      }

      final rangeMeasurements = await ref
        .read(rangeMeasurementRepositoryProvider)
        .getRangeMeasurementsForSession(widget.session.id);
      debugPrint('📊 Loaded ${rangeMeasurements.length} RangeMeasurements');

      // Boot kann gelöscht worden sein — Upload läuft dann ohne Bootsinfos
      final boatId = widget.session.boatId;
      final boat = boatId == null
          ? null
          : await ref.read(boatRepositoryProvider).getBoatById(boatId);

      debugPrint('🚀 Uploading to Supabase...');
      await ref
          .read(uploadServiceProvider)
          .uploadSession(widget.session, boat, points, rangeMeasurements, training.id);
      debugPrint('✅ Upload successful');

      if (!mounted) return;
      setState(() => _step = _UploadStep.done);
    } catch (e) {
      debugPrint('uploadSession failed: $e');
      if (!mounted) return;
      // Dank Upsert ist ein erneuter Versuch immer sicher
      setState(() {
        _step = _UploadStep.confirm;
        _error = 'Upload fehlgeschlagen — bitte erneut versuchen';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _step == _UploadStep.resolving || _step == _UploadStep.uploading;

    return PopScope(
      // Während Netz-Operationen nicht wegschließbar (Zurück-Taste)
      canPop: !busy,
      child: AlertDialog(
        title: const Text('Session einreichen'),
        content: _buildContent(),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _UploadStep.enterCode:
        return TextField(
          controller: _codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Trainings-Code',
            hintText: 'z. B. WIND42',
            errorText: _error,
          ),
          onSubmitted: (_) => _resolve(),
        );

      case _UploadStep.resolving:
        return const _BusyIndicator(label: 'Code wird geprüft…');

      case _UploadStep.confirm:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '„${widget.session.name}" einreichen bei\n'),
                  TextSpan(
                    text: _training?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        );

      case _UploadStep.uploading:
        return const _BusyIndicator(label: 'Session wird hochgeladen…');

      case _UploadStep.done:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 12),
            Flexible(child: Text('Session wurde eingereicht')),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_step) {
      case _UploadStep.enterCode:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(onPressed: _resolve, child: const Text('Weiter')),
        ];

      case _UploadStep.confirm:
        return [
          TextButton(
            onPressed: () => setState(() {
              _step = _UploadStep.enterCode;
              _error = null;
            }),
            child: const Text('Zurück'),
          ),
          FilledButton(onPressed: _upload, child: const Text('Hochladen')),
        ];

      case _UploadStep.resolving:
      case _UploadStep.uploading:
        return const []; // keine Aktionen während Netz-Operationen

      case _UploadStep.done:
        return [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ];
    }
  }
}

class _BusyIndicator extends StatelessWidget {
  final String label;
  const _BusyIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 16),
        Flexible(child: Text(label)),
      ],
    );
  }
}
