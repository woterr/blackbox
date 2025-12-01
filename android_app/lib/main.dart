import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'gmaps.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/ride_history.dart';
import 'dart:math';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('ride_logs'); // Local storage box
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BlackBox',
      theme: ThemeData.dark(),

    home: const BLEHomePage(),
    );
  }
}

class BLEHomePage extends StatefulWidget {
  const BLEHomePage({super.key});

  @override
  State<BLEHomePage> createState() => _BLEHomePageState();
}

class _BLEHomePageState extends State<BLEHomePage> with WidgetsBindingObserver {
  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  Map<String, dynamic>? jsonData;
  bool isConnecting = false;
  String status = "🟡 Waiting for connection...";
  static const targetName = "ESP32_GPS_MPU";
  final ValueNotifier<Map<String, dynamic>> telemetry = ValueNotifier(<String, dynamic>{});

  final ValueNotifier<List<LatLng>> gpsPoints = ValueNotifier([]);
  final ValueNotifier<String> connectionStatus = ValueNotifier("Idle");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPermissionsAndConnect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectAll();
    gpsPoints.dispose();
    connectionStatus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initPermissionsAndConnect();
    }
  }

  // ✅ Permissions & Bluetooth init
  Future<void> _initPermissionsAndConnect() async {
    connectionStatus.value = "🧩 Checking permissions...";
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (await FlutterBluePlus.isSupported == false) {
      connectionStatus.value = "❌ Bluetooth not supported";
      return;
    }

    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;

    _autoConnectToESP();
  }

  // ✅ Disconnect
  Future<void> _disconnectAll() async {
    var devices = await FlutterBluePlus.connectedDevices;
    for (var d in devices) {
      try {
        await d.disconnect();
      } catch (_) {}
    }
  }

  // ✅ Auto connect to ESP
  Future<void> _autoConnectToESP() async {
    if (isConnecting) return;
    isConnecting = true;

    connectionStatus.value = "🔍 Scanning for $targetName...";
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        String name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;

        if (name == targetName) {
          await FlutterBluePlus.stopScan();
          _targetDevice = r.device;
          connectionStatus.value = "🔗 Connecting to $targetName...";

          try {
            await _targetDevice!.connect(license: License.free, autoConnect: false);
            await _targetDevice!.requestMtu(247);
            connectionStatus.value = "✅ Connected to $targetName";
            isConnecting = false;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ Connected to $targetName"),
                backgroundColor: Colors.green.shade600,
                duration: const Duration(seconds: 2),
              ),
            );
            List<BluetoothService> services =
            await _targetDevice!.discoverServices();

            for (var s in services) {
              for (var c in s.characteristics) {
                if (c.uuid.toString().toLowerCase() ==
                    "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
                  _targetCharacteristic = c;
                  await c.setNotifyValue(true);

                  c.onValueReceived.listen((value) async {
                    try {
                      var decoded = jsonDecode(utf8.decode(value));
                      // ✅ Update Map Polyline (if lat/lng valid)

                      if (decoded.containsKey('lat') && decoded.containsKey('lng')) {
                        double? lat = (decoded['lat'] is num) ? decoded['lat'] * 1.0 : null;
                        double? lng = (decoded['lng'] is num) ? decoded['lng'] * 1.0 : null;
                        final ax = (jsonData?["ax"] ?? 0).toDouble();
                        final ay = (jsonData?["ay"] ?? 0).toDouble();
                        final az = (jsonData?["az"] ?? 0).toDouble();
                        double tiltDeg = 0;

                        try {
                          tiltDeg = atan2(sqrt(ax * ax + ay * ay), az) * 180 / pi;
                          tiltDeg = tiltDeg.isNaN ? 0 : tiltDeg;
                        } catch (e) {
                          tiltDeg = 0;
                        }
                        decoded['tilt'] = tiltDeg;
                        if (tiltDeg > 30){
                          decoded['motion_state'] = "Bike";
                        }

                        if(decoded["spd"] >= 4.5){
                          decoded['motion_state'] = "Scooter";
                        }else if (decoded['motion_state'] == "Running"){
                          decoded['motion_state'] = "Scooter";
                    }
                        if (lat != null && lng != null && lat != 0 && lng != 0) {
                          gpsPoints.value = [...gpsPoints.value, LatLng(lat, lng)];
                        }
                      }
                      telemetry.value = decoded;

                      // ✅ Update UI data
                      setState(() => jsonData = decoded);
                    } catch (e) {
                      debugPrint("❌ Invalid BLE JSON: $e");
                    }
                  });
                }
              }
            }


            _targetDevice!.connectionState.listen((state) {
              if (state == BluetoothConnectionState.disconnected) {
                connectionStatus.value = "❌ Disconnected, retrying...";
                Future.delayed(const Duration(seconds: 3), _autoConnectToESP);
              }
            });
          } catch (e) {
            isConnecting = false;
            connectionStatus.value = "⚠️ Connection failed: $e";
            Future.delayed(const Duration(seconds: 3), _autoConnectToESP);
          }
          break;
        }
      }
    });
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BlackBox"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      // ✅ Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bike, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    "BlackBox",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Smart Ride Logger",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Ride History"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RideHistoryPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: GPSMapScreen(
        gpsPoints: gpsPoints,
        connectionStatus: connectionStatus,
        telemetry: telemetry,                   // 👈 NEW
      ),
    );
  }
}
