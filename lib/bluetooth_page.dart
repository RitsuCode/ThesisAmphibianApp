// lib/bluetooth_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

/// Discovers Classic-BT devices (HC-05, etc.) and returns the
/// selected BluetoothDevice to the caller.
class BluetoothDevicesPage extends StatefulWidget {
  const BluetoothDevicesPage({Key? key}) : super(key: key);

  @override
  State<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStream;
  final List<BluetoothDiscoveryResult> _results = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndDiscover();
  }

  @override
  void dispose() {
    _discoveryStream?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissionsAndDiscover() async {
    // Android 12+ needs these; Classic discovery needs location too
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    _startDiscovery();
  }

  void _startDiscovery() {
    setState(() {
      _results.clear();
      _isDiscovering = true;
    });

    _discoveryStream = FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((r) {
      setState(() {
        final idx = _results.indexWhere(
            (e) => e.device.address == r.device.address);
        if (idx >= 0) {
          _results[idx] = r;
        } else {
          _results.add(r);
        }
      });
    }, onDone: () {
      setState(() => _isDiscovering = false);
    });
  }

  void _cancelDiscovery() {
    _discoveryStream?.cancel();
    setState(() => _isDiscovering = false);
  }

  /// Called when user taps “Select”:
  void _selectDevice(BluetoothDevice device) {
    Navigator.pop(context, device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Bluetooth Device'),
        actions: [
          _isDiscovering
              ? IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _cancelDiscovery,
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _startDiscovery,
                )
        ],
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (_, idx) {
          final result = _results[idx];
          final device = result.device;
          return ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(device.name ?? 'Unknown Device'),
            subtitle: Text(device.address),
            trailing: ElevatedButton(
              child: const Text('Select'),
              onPressed: () => _selectDevice(device),
            ),
          );
        },
      ),
    );
  }
}
