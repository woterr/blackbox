import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InfoPanel extends StatelessWidget {
  final ScrollController scrollController;
  final ValueNotifier<String> connectionStatus;
  final ValueNotifier<Map<String, dynamic>> telemetry;

  const InfoPanel({
    super.key,
    required this.scrollController,
    required this.connectionStatus,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: telemetry,
      builder: (context, jsonData, _) {
        if (jsonData.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("No data received yet", style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        final motionState = (jsonData["motion_state"] ?? "Unknown").toString();
        final motionColor = _motionColor(motionState);

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // drag handle
            Center(
              child: Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // header
            Center(
              child: Column(
                children: const [
                  Icon(LucideIcons.activity, color: Colors.white70, size: 32),
                  SizedBox(height: 6),
                  Text("Ride Telemetry",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // motion state
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: motionColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: motionColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.activity, color: motionColor, size: 24),
                  const SizedBox(width: 8),
                  Text("Motion: $motionState",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: motionColor)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // connection status
            ValueListenableBuilder<String>(
              valueListenable: connectionStatus,
              builder: (context, status, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bluetooth,
                      color: status.contains("Connected") ? Colors.greenAccent : Colors.orangeAccent, size: 20),
                  const SizedBox(width: 6),
                  Text(status, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24),

            // sensor grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.6, // ⚙️ Taller tiles — prevents overflow
              children: [
                _buildDataTile("Lat", jsonData["lat"]),
                _buildDataTile("Lng", jsonData["lng"]),
                _buildDataTile("Speed", "${jsonData["spd"] ?? "N/A"} km/h"),
                _buildDataTile("Tilt", jsonData["tilt"]),
                _buildDataTile("AX", jsonData["ax"]),
                _buildDataTile("AY", jsonData["ay"]),
                _buildDataTile("AZ", jsonData["az"]),
                _buildDataTile("Temp", "${jsonData["temp"] ?? "N/A"}°C"),
              ],
            ),

            const Divider(color: Colors.white24),

            // if (jsonData.containsKey("timestamp"))
            //   Center(
            //     child: Text("📅 ${jsonData["timestamp"]}",
            //         style: const TextStyle(color: Colors.white54, fontSize: 14)),
            //   ),
          ],
        );
      },
    );
  }

  Widget _buildDataTile(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[800]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value?.toString() ?? "—",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color _motionColor(String motion) {
    switch (motion.toLowerCase()) {
      case "walking": return Colors.greenAccent;
      case "running": return Colors.orangeAccent;
      case "stationary": return Colors.blueAccent;
      default: return Colors.white;
    }
  }
}
