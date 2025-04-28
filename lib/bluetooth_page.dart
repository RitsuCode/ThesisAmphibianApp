import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this package in pubspec.yaml

class BluetoothDevicesPage extends StatefulWidget {
  const BluetoothDevicesPage({super.key});

  @override
  State<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  List<BluetoothDevice> _availableDevices = [];
  List<BluetoothDevice> _connectedDevices = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final List<StreamSubscription> _deviceSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    // Optionally, start scanning automatically:
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    for (var sub in _deviceSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    // Request Bluetooth and location permissions (required for Bluetooth scanning on Android)
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check if Bluetooth is available
    if (!await FlutterBluePlus.isAvailable) {
      _showMessage("Bluetooth not available on this device");
      return;
    }

    // Listen for scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _availableDevices = results
            .map((r) => r.device)
            .where((d) =>
                !_connectedDevices.any((cd) => cd.remoteId == d.remoteId))
            .toList();
      });
    });

    // Get already connected devices
    _connectedDevices = await FlutterBluePlus.connectedDevices;
    for (var device in _connectedDevices) {
      _listenToDeviceConnection(device);
    }
    if (mounted) setState(() {});
  }

  void _listenToDeviceConnection(BluetoothDevice device) {
    _deviceSubscriptions.add(
      device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevices.remove(device);
          if (mounted) setState(() {});
        }
      }),
    );
  }

  Future<void> _startScan() async {
    try {
      // Turn on Bluetooth if not on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      setState(() {
        _isScanning = true;
        _availableDevices.clear();
      });

      // Start scan with a timeout of 15 seconds
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      _showMessage("Scan error: $e");
      setState(() => _isScanning = false);
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      _listenToDeviceConnection(device);
      _connectedDevices.add(device);
      if (mounted) {
        setState(() {});
        _showMessage('Connected to ${device.platformName}');
      }
    } catch (e) {
      _showMessage('Failed to connect: $e');
    }
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      _connectedDevices.remove(device);
      if (mounted) {
        setState(() {});
        _showMessage('Disconnected from ${device.platformName}');
      }
    } catch (e) {
      _showMessage('Failed to disconnect: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Devices"),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.search),
            onPressed: _isScanning ? _stopScan : _startScan,
            tooltip: _isScanning ? "Stop Scan" : "Start Scan",
          ),
        ],
      ),
      body: ListView(
        children: [
          // Connected devices section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Connected Devices", style: TextStyle(fontSize: 20)),
          ),
          ..._connectedDevices.map(
            (device) => DeviceTile(
              device: device,
              isConnected: true,
              onDisconnect: () => _disconnectDevice(device),
            ),
          ),

          // Available devices section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text("Available Devices", style: TextStyle(fontSize: 20)),
                if (_isScanning) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
          ..._availableDevices.map(
            (device) => DeviceTile(
              device: device,
              isConnected: false,
              onConnect: () => _connectToDevice(device),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final bool isConnected;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const DeviceTile({
    super.key,
    required this.device,
    required this.isConnected,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
      title: Text(device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown Device'),
      subtitle: Text(device.remoteId.toString()),
      trailing: isConnected
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onDisconnect,
            )
          : ElevatedButton(
              onPressed: onConnect,
              child: const Text("Connect"),
            ),
    );
  }
}
