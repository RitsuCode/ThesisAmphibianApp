import 'package:flutter/material.dart';

class BluetoothDevicesPage extends StatelessWidget {
  const BluetoothDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final availableDevices = ["ESP32 Amphibian", "My Speaker", "Unknown Device"];
    final connectedDevices = ["ESP32 Amphibian"];

    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Devices")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Connected Devices", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            ...connectedDevices.map(
              (device) => ListTile(
                leading: const Icon(Icons.bluetooth_connected),
                title: Text(device),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
            const Divider(height: 40),
            const Text("Available Devices", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            ...availableDevices.map(
              (device) => ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(device),
                trailing: ElevatedButton(
                  onPressed: () {
                    // TODO: implement pairing logic
                    print("Connecting to $device");
                  },
                  child: const Text("Connect"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}