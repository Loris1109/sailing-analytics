import 'package:flutter/material.dart';

/// Fragt den Namen für einen Ausschnitt ab. Gibt den Namen zurück oder null,
/// wenn abgebrochen wurde.
///
/// Vorbelegt mit der Zeitspanne: das ist immer richtig und immer eindeutig,
/// und wer „Rennen 2" will, tippt es drüber. Ein leeres Feld hätte an dieser
/// Stelle nur eine zusätzliche Hürde zwischen Ziehen und Speichern gelegt.
Future<String?> showSaveClipDialog(
  BuildContext context, {
  required DateTime start,
  required DateTime end,
}) async {
  final controller = TextEditingController(text: '${_hm(start)}–${_hm(end)}');

  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ausschnitt speichern'),
      content: TextField(
        controller: controller,
        autofocus: true,
        // Der Vorschlag ist komplett markiert: einmal tippen überschreibt
        // ihn, einmal ans Ende tippen behält ihn.
        onTap: () => controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        ),
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Speichern'),
        ),
      ],
    ),
  );

  if (name == null || name.isEmpty) return null;
  return name;
}

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
