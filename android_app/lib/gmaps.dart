import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'widgets/info_panel.dart';

class GPSMapScreen extends StatefulWidget {
  final ValueNotifier<List<LatLng>> gpsPoints;
  final ValueNotifier<String> connectionStatus;
  final ValueNotifier<Map<String, dynamic>> telemetry;

  const GPSMapScreen({
    super.key,
    required this.gpsPoints,
    required this.connectionStatus,
    required this.telemetry,
  });

  @override
  State<GPSMapScreen> createState() => _GPSMapScreenState();
}

class _GPSMapScreenState extends State<GPSMapScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🗺️ Google Map with live polyline (unchanged)
          ValueListenableBuilder<List<LatLng>>(
            valueListenable: widget.gpsPoints,
            builder: (context, points, _) {
              // Optional: follow the last point
              if (_mapController != null && points.isNotEmpty) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(points.last),
                );
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: points.isNotEmpty
                      ? points.last
                      : const LatLng(12.8615, 77.6647),
                  zoom: 16,
                ),
                onMapCreated: (controller) => _mapController = controller,
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("path"),
                    color: Colors.blueAccent,
                    width: 6,
                    points: points,
                  ),
                },
                markers: points.isNotEmpty
                    ? {
                  Marker(
                    markerId: const MarkerId("current"),
                    position: points.last,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  ),
                }
                    : {},
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
              );
            },
          ),

          // 🟪 Sliding panel (same API, just passes telemetry down)
          SlidingUpPanel(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: const Color(0xFF121212),
            minHeight: 140,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            parallaxEnabled: true,
            parallaxOffset: 0.2,
            panelBuilder: (scrollController) => InfoPanel(
              scrollController: scrollController,
              connectionStatus: widget.connectionStatus,
              telemetry: widget.telemetry, // motion_state comes from here
            ),
            body: const SizedBox.shrink(),
          ),

          // 📶 Connection status banner (unchanged)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<String>(
                valueListenable: widget.connectionStatus,
                builder: (context, status, _) => Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
