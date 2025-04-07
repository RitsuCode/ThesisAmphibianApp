import 'package:flutter/material.dart';
import 'bluetooth_page.dart';

class AmphibianController extends StatelessWidget {
  const AmphibianController({super.key});

  void sendToArduino(String command) {
    // TODO: Replace with actual Bluetooth send logic
    print("Sending: $command");
  }

  Widget bigArrowButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.blueGrey,
        ),
        child: Icon(icon, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Amphibian Boat Controller"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothDevicesPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Camera Feed
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey.shade600, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Camera Feed",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 40),

            /// Horizontal layout for buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// D-Pad
                Column(
                  children: [
                    bigArrowButton(Icons.arrow_drop_up, () => sendToArduino("F")),
                    Row(
                      children: [
                        bigArrowButton(Icons.arrow_left, () => sendToArduino("L")),
                        const SizedBox(width: 60),
                        bigArrowButton(Icons.arrow_right, () => sendToArduino("R")),
                      ],
                    ),
                    bigArrowButton(Icons.arrow_drop_down, () => sendToArduino("B")),
                  ],
                ),

                const SizedBox(width: 30),

                /// Circular Lift Shovel Button
                ElevatedButton(
                  onPressed: () => sendToArduino("S"),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(24),
                  ),
                  child: const Icon(Icons.construction, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
