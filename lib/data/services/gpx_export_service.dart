// lib/data/services/gpx_export_service.dart
// Builds a GPX 1.1 document from a session — pure string logic, no I/O.
// Writing the file and opening the share sheet happens at the UI layer.

import 'package:tacktics/data/entities/range_measurements.dart';

import '../entities/boat.dart';
import '../entities/gps_point.dart';
import '../entities/session.dart';

class GpxExportService {
  /// [clipName] wird gesetzt, wenn nur ein Ausschnitt der Session exportiert
  /// wird. Er steht dann als Titel in der Datei, und der Sessionname wandert
  /// in die Beschreibung — sonst hieße die Datei wie die ganze Aufzeichnung
  /// und niemand sähe ihr an, dass nur ein Lauf drin ist.
  String buildGpx(
    SessionEntity session,
    BoatEntity? boat,
    List<GpsPointEntity> points,
    List<RangeMeasurementEntity> rangeMeasurements, {
    String? clipName,
  }) {
    final title = clipName ?? session.name;
    // Erster Punkt statt session.startTime: bei einem Ausschnitt beginnt die
    // Spur später als die Aufzeichnung. Für eine ganze Session ist es
    // derselbe Zeitpunkt.
    final start = points.isNotEmpty ? points.first.timestamp : session.startTime;

    final b = StringBuffer();
    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln('<gpx version="1.1" creator="Tacktics"');
    b.writeln('     xmlns="http://www.topografix.com/GPX/1/1"');
    b.writeln('     xmlns:st="https://tacktics.app/gpx/1">');

    b.writeln('  <metadata>');
    b.writeln('    <name>${_escapeXml(title)}</name>');
    b.writeln('    <time>${_formatTime(start)}</time>');
    final wind = session.windDirection;
    if (boat != null || wind != null) {
      b.writeln('    <extensions>');
      if (wind != null) {
        // Sailor's input, deliberately exported raw — TWA/VMG stay out of
        // the file so tracks from different sailors remain comparable
        b.writeln(
          '      <st:windDirection>${wind.toStringAsFixed(1)}</st:windDirection>',
        );
      }
      if (boat != null) {
        b.writeln('      <st:boat>');
        b.writeln('        <st:name>${_escapeXml(boat.name)}</st:name>');
        b.writeln(
          '        <st:sailNumber>${_escapeXml(boat.sailNumber)}</st:sailNumber>',
        );
        b.writeln('        <st:class>${_escapeXml(boat.boatClass)}</st:class>');
        b.writeln('      </st:boat>');
      }
      b.writeln('    </extensions>');
    }
    b.writeln('  </metadata>');

    b.writeln('  <trk>');
    b.writeln('    <name>${_escapeXml(title)}</name>');
    final desc = [
      if (clipName != null) 'Ausschnitt aus ${session.name}',
      if (boat != null) '${boat.boatClass} – ${boat.sailNumber} (${boat.name})',
    ].join(' · ');
    if (desc.isNotEmpty) {
      b.writeln('    <desc>${_escapeXml(desc)}</desc>');
    }
    b.writeln('    <type>Sailing</type>');
    b.writeln('    <trkseg>');
    for (final p in points) {
      b.writeln(
        '      <trkpt lat="${p.lat.toStringAsFixed(6)}" '
        'lon="${p.lon.toStringAsFixed(6)}">',
      );
      b.writeln('        <time>${_formatTime(p.timestamp)}</time>');
      b.writeln('        <extensions>');
      b.writeln('          <st:sog>${p.sog.toStringAsFixed(1)}</st:sog>');
      b.writeln('          <st:cog>${p.cog.toStringAsFixed(1)}</st:cog>');
      b.writeln('          <st:heading>${p.magHeading.toStringAsFixed(1)}</st:heading>');
      b.writeln('          <st:heel>${p.heel.toStringAsFixed(1)}</st:heel>');

      final measurementsForPoint = rangeMeasurements
          .where((m) => m.gpsPointId == p.id)
          .toList();
      
      if (measurementsForPoint.isNotEmpty) {
        b.writeln('          <st:rangeMeasurements>');
        for (final m in measurementsForPoint) {
          b.writeln('            <st:measurement>');
          b.writeln('              <st:peerId>${_escapeXml(m.peerId)}</st:peerId>');
          b.writeln('              <st:tech>${m.tech}</st:tech>');
          if (m.rssi != null) {
            b.writeln('              <st:rssi>${m.rssi}</st:rssi>');
          }
          if (m.distance != null) {
            b.writeln('              <st:distance>${m.distance}</st:distance>');
          }
          if (m.quality != null) {
            b.writeln('              <st:quality>${m.quality}</st:quality>');
          }
          b.writeln('            </st:measurement>');
        }
        b.writeln('          </st:rangeMeasurements>');
      }
      b.writeln('        </extensions>');
      b.writeln('      </trkpt>');
    }
    b.writeln('    </trkseg>');
    b.writeln('  </trk>');
    b.write('</gpx>');
    return b.toString();
  }

  // Filesystem-safe name, e.g. "Training 10.6.26" → "Training_10_6_26.gpx"
  //
  // Mit [clipName] kommt der Ausschnitt hinten dran, damit zwei Läufe
  // derselben Session nicht dieselbe Datei ergeben.
  String fileNameFor(SessionEntity session, {String? clipName}) {
    final parts = [session.name, ?clipName];
    final safeName = parts
        .join('_')
        .replaceAll(RegExp(r'[^\w\-]+'), '_');
    return '$safeName.gpx';
  }

  // & must be replaced first, otherwise the other escapes get double-escaped
  String _escapeXml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  // GPX requires UTC (xsd:dateTime with trailing Z)
  String _formatTime(DateTime t) => t.toUtc().toIso8601String();
}
