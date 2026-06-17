import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sailing_analytics/data/entities/gps_point.dart';
import 'package:sailing_analytics/providers/ui_providers.dart';
import 'package:sailing_analytics/util/color_utils.dart';

class MapWidget extends StatefulWidget {
  final List<GpsPointEntity> gpsPoints;
  final LatLng? curPosition;
  final MapController mapController;
  final Function(MapEvent)? onMapEvent;
  final PathMode pathMode;
  final double maxKnots;

  const MapWidget({
    super.key,
    required this.gpsPoints,
    required this.curPosition,
    required this.mapController,
    required this.pathMode,
    required this.maxKnots,
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
                    PathMode.heel => heelToColor(widget.gpsPoints[i].heel, 45),
                  },
                ),
            ],
          ),
      ],
    );
  }
}
