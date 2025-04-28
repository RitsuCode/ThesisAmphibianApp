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
    width: 60,
    height: 60,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        backgroundColor: Colors.blueGrey,
        padding: EdgeInsets.zero, // Add this line
      ),
      child: Center(
        child: Icon(icon, size: 30),
      ),
    ),
  );
}

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade600, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          const Text(
            "Status: ",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          // Empty container you can fill later with status text
          Container(
            width: 100, // Adjust width as needed
            child: const Text(
              "Ready", // Default text, change this dynamically later
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          // Progress bar you can use to show fill level
          Expanded(
            child: LinearProgressIndicator(
              value: 0.0, // Set this value between 0.0-1.0 later
              backgroundColor: Colors.grey[600],
              color: Colors.blue,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
        child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        /// Status Bar at the top
        _buildStatusBar(),
        const SizedBox(height: 20),

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
    );
  }

  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        /// Status Bar at the top
        _buildStatusBar(),
        const SizedBox(height: 20),
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Left side - Arrow buttons
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
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

              const SizedBox(width: 20),

              /// Center - Camera Feed
              Expanded(
                child: Container(
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
              ),

              const SizedBox(width: 20),

              /// Right side - Action button
              Center(
                child: ElevatedButton(
                  onPressed: () => sendToArduino("S"),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(24),
                  ),
                  child: const Icon(Icons.construction, size: 32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}