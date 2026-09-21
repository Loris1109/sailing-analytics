import 'package:flutter/material.dart';

/// Das aufgezogene Gegenstück zum TrimBody — dieselbe Geste wie im
/// Normalmodus (hochziehen zeigt die Liste), nur ist der Gegenstand hier
/// nicht die Sessionliste, sondern die gespeicherten Ausschnitte der
/// ausgewählten Session.
///
/// Noch leer: gespeicherte Ausschnitte gibt es erst, wenn der Brush steht.
/// Hierher gehören später auch die Aktionen mit Folgen — einen Ausschnitt
/// festschreiben, die Session dauerhaft kürzen —, damit die Ebene mit den
/// Handles beim Ziehen aufgeräumt bleibt.
class TrimClipsBody extends StatelessWidget {
  const TrimClipsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Keine gespeicherten Ausschnitte',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
