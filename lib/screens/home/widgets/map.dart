import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tacktics/data/entities/gps_point.dart';
import 'package:tacktics/providers/ui_providers.dart';
import 'package:tacktics/screens/home/widgets/SlideMenu/slide_menu.dart';
import 'package:tacktics/data/services/map_tiles.dart';
import 'package:tacktics/util/color_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class MapWidget extends StatefulWidget {
  final List<GpsPointEntity> gpsPoints;
  final LatLng? curPosition;
  final MapController mapController;
  final Function(MapEvent)? onMapEvent;
  final PathMode pathMode;
  final double maxKnots;

  /// Kachelquelle mit Plattencache.  = ohne Cache laden, siehe
  /// tileProviderProvider.
  final TileProvider? tileProvider;

  const MapWidget({
    super.key,
    required this.gpsPoints,
    required this.curPosition,
    required this.mapController,
    required this.pathMode,
    required this.maxKnots,
    this.tileProvider,
    this.onMapEvent,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

/// Höhe der Attributionszeile. Gilt für Logo, Knöpfe und die Reihe selbst —
/// laufen die auseinander, sitzt das Logo neben statt in der Zeile.
const _attributionHeight = 16.0;

/// Der ⓘ-Knopf, auf Zeilenmaß gebracht.
///
/// Material legt um jeden Knopf ein Berührungsfeld von 48 dp — die Regel, die
/// dafür sorgt, dass man Knöpfe auch mit nassen Fingern trifft. Neben einem
/// 16 dp hohen Logo wird daraus sichtbar leerer Raum: das Symbol sitzt mittig
/// in einem viermal so breiten Kasten, und zwischen ihm und der Wortmarke
/// klafft eine Lücke, die nach Fehler aussieht.
///
/// `shrinkWrap` nimmt die Automatik heraus, `minimumSize` setzt stattdessen
/// ein eigenes Maß: 28 dp sind ein Kompromiss — kleiner als die Richtlinie
/// verlangt, aber immer noch zu treffen, und die verbleibenden 6 dp neben dem
/// Symbol lesen sich als Abstand statt als Loch. Für einen Knopf, der einmal
/// im Jahr gedrückt wird, ist das der richtige Tausch.
final _attributionButtonStyle = IconButton.styleFrom(
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  minimumSize: const Size.square(28),
  padding: EdgeInsets.zero,
);

/// Wie weit die Attribution über den unteren Rand gehoben wird, damit sie
/// knapp über dem zugeklappten SlideMenu sitzt.
///
/// Das Widget bringt selbst eine `SafeArea` und 6 px Innenabstand mit — beides
/// schiebt es zusätzlich nach oben. Ohne dieses Gegenrechnen steht die Zeile
/// auf Geräten mit Gestenleiste rund 40 dp zu hoch und schwebt sichtbar über
/// dem Panel.
double _attributionLift(BuildContext context) {
  const gap = 4.0; // Luft zwischen Zeile und Panelkante
  const inner = 6.0; // fester Innenabstand des RichAttributionWidget
  final safeArea = MediaQuery.paddingOf(context).bottom;
  return (kSlideMenuCollapsedCover - safeArea - inner - gap).clamp(
    0.0,
    kSlideMenuCollapsedCover,
  );
}

class _MapWidgetState extends State<MapWidget> {
  bool _isValidLatLng(double lat, double lon) {
    return lat.isFinite && lon.isFinite;
  }

  @override
  void didUpdateWidget(MapWidget old) {
    super.didUpdateWidget(old);

    if (widget.gpsPoints.length > 1 &&
        widget.gpsPoints.first.sessionId !=
            old.gpsPoints.firstOrNull?.sessionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latLngs = widget.gpsPoints
            .map((p) => LatLng(p.lat, p.lon))
            .where(
              (latlng) => latlng.latitude.isFinite && latlng.longitude.isFinite,
            )
            .toList();
        if (latLngs.length > 1) {
          widget.mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(latLngs),
              padding: const EdgeInsets.all(48),
            ),
          );
        }
      });
    } else if (widget.curPosition != null &&
        old.curPosition == null &&
        widget.curPosition!.latitude.isFinite &&
        widget.curPosition!.longitude.isFinite) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.mapController.move(widget.curPosition!, 14);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speeds = widget.gpsPoints.map((p) => p.sog);
    final minSpeed = speeds.isEmpty ? 0.0 : speeds.reduce(min);
    final maxSpeed = speeds.isEmpty ? 1.0 : speeds.reduce(max);
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        onMapEvent: widget.onMapEvent,
        initialCenter: const LatLng(54.0, 10.0),
        initialZoom: 14,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        if (MapTiles.isConfigured)
          TileLayer(
            urlTemplate: MapTiles.urlTemplate,
            userAgentPackageName: 'app.tacktics',
            tileProvider: widget.tileProvider,
            // Gehört zu den 512er Kacheln, siehe MapTiles.urlTemplate.
            // Ohne das Paar zeigt die Karte konsequent eine Stufe zu nah.
            tileDimension: 512,
            zoomOffset: -1,
          )
        else
          const _MissingTokenHint(),
        if (widget.gpsPoints.length > 1)
          PolylineLayer(
            polylines: [
              for (int i = 0; i < widget.gpsPoints.length - 1; i++)
                if (_isValidLatLng(
                      widget.gpsPoints[i].lat,
                      widget.gpsPoints[i].lon,
                    ) &&
                    _isValidLatLng(
                      widget.gpsPoints[i + 1].lat,
                      widget.gpsPoints[i + 1].lon,
                    ))
                  Polyline(
                    points: [
                      LatLng(widget.gpsPoints[i].lat, widget.gpsPoints[i].lon),
                      LatLng(
                        widget.gpsPoints[i + 1].lat,
                        widget.gpsPoints[i + 1].lon,
                      ),
                    ],
                    strokeWidth: 4.0,
                    color: switch (widget.pathMode) {
                      PathMode.speed => speedToColor(
                        widget.gpsPoints[i].sog,
                        0.0,
                        //max Speed from session
                        widget.maxKnots,
                      ),
                      PathMode.dynamicSpeed => speedToColor(
                        widget.gpsPoints[i].sog,
                        minSpeed,
                        //max Speed from session
                        maxSpeed,
                      ),
                      PathMode.heel => heelToColor(
                        widget.gpsPoints[i].heel,
                        45,
                      ),
                    },
                  ),
            ],
          ),

        if (MapTiles.isConfigured)
          Padding(
            padding: EdgeInsets.only(bottom: _attributionLift(context)),
            child: RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              permanentHeight: _attributionHeight,
              showFlutterMapAttribution: false,
              popupInitialDisplayDuration: Duration.zero,
              openButton: (context, open) => IconButton(
                onPressed: open,
                tooltip: 'Kartenquellen',
                style: _attributionButtonStyle,
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: _attributionHeight,
                  color: Colors.black54,
                ),
              ),
              closeButton: (context, close) => IconButton(
                onPressed: close,
                tooltip: 'Schließen',
                style: _attributionButtonStyle,
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: _attributionHeight,
                  color: Colors.black54,
                ),
              ),
              attributions: [
                LogoSourceAttribution(
                  Image.asset(
                    'assets/mapbox/mapbox-logo.png',
                    // Fehlt die Datei noch, bleibt der Nachweis als Text
                    // stehen statt als rotes Fehlerkästchen. Für die
                    // Bedingungen reicht das NICHT — das Logo muss rein.
                    errorBuilder: (_, _, _) => const Center(
                      child: Text(
                        'Mapbox',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ),
                  height: _attributionHeight,
                  tooltip: 'Mapbox',
                  onTap: () => launchUrl(Uri.parse(MapTiles.attributionMapbox)),
                ),
                TextSourceAttribution(
                  'Mapbox',
                  onTap: () => launchUrl(Uri.parse(MapTiles.attributionMapbox)),
                ),
                TextSourceAttribution(
                  'Karte verbessern',
                  prependCopyright: false,
                  onTap: () => launchUrl(Uri.parse(MapTiles.improveMap)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Steht anstelle der Kacheln, wenn ohne `MAPBOX_TOKEN` gebaut wurde.
///
/// Sagt, was fehlt, statt ein graues Feld zu zeigen — das sähe aus wie ein
/// Fehler im Kartenmaterial und nicht wie eine vergessene Bauoption.
class _MissingTokenHint extends StatelessWidget {
  const _MissingTokenHint();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFE8EAED),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Keine Kartenquelle.\nMit --dart-define=MAPBOX_TOKEN=… bauen.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ),
    ),
  );
}
