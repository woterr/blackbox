import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final box = Hive.box('ride_logs');
    final all = box.values.cast<Map>().toList();

    // Sort newest first
    all.sort((a, b) => DateTime.parse(b["timestamp"])
        .compareTo(DateTime.parse(a["timestamp"])));

    setState(() => logs = all.cast<Map<String, dynamic>>());
  }

  void _copyAllLogs() {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No logs available to copy")),
      );
      return;
    }

    final jsonData = const JsonEncoder.withIndent('  ').convert(logs);
    Clipboard.setData(ClipboardData(text: jsonData));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All logs copied to clipboard 📋")),
    );
  }

  void _copySingleLog(Map<String, dynamic> log) {
    final jsonData = const JsonEncoder.withIndent('  ').convert(log);
    Clipboard.setData(ClipboardData(text: jsonData));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Log copied to clipboard 📋")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Ride History"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: "Copy all logs",
            onPressed: _copyAllLogs,
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
        child: Text(
          "No ride logs yet",
          style: TextStyle(color: Colors.white54),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadLogs,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final timestamp = DateFormat('hh:mm:ss a')
                .format(DateTime.parse(log["timestamp"]));
            final speed = log["spd"]?.toStringAsFixed(1) ?? "–";

            return Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text('${index + 1}',
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text("Log — $timestamp",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                subtitle: Text("Speed: $speed km/h",
                    style: const TextStyle(color: Colors.white54)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white70),
                  onPressed: () => _copySingleLog(log),
                ),
                onTap: () => _showLogDetails(context, log),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogDetails(BuildContext context, Map<String, dynamic> log) {
    final time =
    DateFormat('hh:mm:ss a').format(DateTime.parse(log["timestamp"]));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text("Data Timestamp — $time",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const Divider(color: Colors.white24, height: 24),
              ...log.entries.map((e) {
                if (e.key == "timestamp") return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.toUpperCase(),
                          style: const TextStyle(color: Colors.white70)),
                      Text(e.value.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _copySingleLog(log);
                      Navigator.pop(context);
                    },
                    child: const Text("Copy",
                        style: TextStyle(color: Colors.deepPurpleAccent)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close",
                        style: TextStyle(color: Colors.grey)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
