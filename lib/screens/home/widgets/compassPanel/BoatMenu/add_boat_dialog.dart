import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/data/entities/boat.dart';
import 'package:sailing_analytics/providers/repository_providers.dart';

const Map<String, double> kBoatClasses = {'Europe': 20.0};

class AddBoatDialog extends ConsumerStatefulWidget {
  const AddBoatDialog({super.key});

  @override
  ConsumerState<AddBoatDialog> createState() => _AddBoatDialogState();
}

class _AddBoatDialogState extends ConsumerState<AddBoatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sailNumberController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedBoatClass;

  @override
  void dispose() {
    _sailNumberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Boot hinzufügen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _sailNumberController,
              decoration: const InputDecoration(labelText: 'Segelnummer'),
              validator: (v) => v == null || v.isEmpty ? 'Pflichtfeld' : null,
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Bootsname'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedBoatClass,
              decoration: const InputDecoration(labelText: 'Bootsklasse'),
              items: kBoatClasses.keys
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBoatClass = v),
              validator: (v) => v == null ? 'Pflichtfeld' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _save, child: const Text('Speichern')),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final boat = BoatEntity(
      id: '',
      sailNumber: _sailNumberController.text.trim(),
      name: _nameController.text.trim(),
      boatClass: _selectedBoatClass!,
      maxSpeed: kBoatClasses[_selectedBoatClass!]!,
      isActive: false,
    );

    await ref.read(boatRepositoryProvider).addBoat(boat);
    if (mounted) Navigator.of(context).pop();
  }
}
