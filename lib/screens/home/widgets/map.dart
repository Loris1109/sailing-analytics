import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';

class MapWidget extends StatefulWidget {
  final List<GpsPointEntity> gpsPoints;
  final LatLng? curPosition;
  final MapController mapController;
  final Function(MapEvent)? onMapEvent;

  const MapWidget({
    super.key,
    required this.gpsPoints,
    required this.curPosition,
    required this.mapController,
    this.onMapEvent,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  void didUpdateWidget(MapWidget old) {
    super.didUpdateWidget(old);

    if (widget.gpsPoints.length > 1 &&
        widget.gpsPoints.first.sessionId !=
            old.gpsPoints.firstOrNull?.sessionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latLngs = widget.gpsPoints
            .map((p) => LatLng(p.lat, p.lon))
            .toList();
        widget.mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(latLngs),
            padding: const EdgeInsets.all(48),
          ),
        );
      });
    } else if (widget.curPosition != null && old.curPosition == null) {
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.Lorenz.sailtrack',
        ),
        if (widget.gpsPoints.length > 1)
          PolylineLayer(
            polylines: [
              for (int i = 0; i < widget.gpsPoints.length - 1; i++)
                Polyline(
                  points: [
                    LatLng(widget.gpsPoints[i].lat, widget.gpsPoints[i].lon),
                    LatLng(
                      widget.gpsPoints[i + 1].lat,
                      widget.gpsPoints[i + 1].lon,
                    ),
                  ],
                  strokeWidth: 4.0,
                  color: _speedToColor(widget.gpsPoints[i].sog, 0.0, 10),
                ),
            ],
          ),
      ],
    );
  }

  Color _speedToColor(double knots, double minKnots, double maxKnots) {
    final t = ((knots - minKnots) / (maxKnots - minKnots)).clamp(0.0, 1.0);
    final hue = 240.0 * (1.0 - t);
    return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
  }
}
