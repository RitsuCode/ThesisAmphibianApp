// lib/controller_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;

import 'bluetooth_page.dart';

class AmphibianController extends StatefulWidget {
  const AmphibianController({Key? key}) : super(key: key);

  @override
  _AmphibianControllerState createState() => _AmphibianControllerState();
}

class _AmphibianControllerState extends State<AmphibianController> {
  static const String streamUrl = 'http://192.168.1.15:81/stream';
  bool isStreamAvailable = false;

  BluetoothDevice? _device;
  BluetoothConnection? _connection;

  Timer? _repeatTimer;

  @override
  void initState() {
    super.initState();
    _checkStream();
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  Future<void> _checkStream() async {
    try {
      final resp = await http
          .head(Uri.parse(streamUrl))
          .timeout(const Duration(seconds: 5));
      setState(() => isStreamAvailable = resp.statusCode == 200);
    } catch (_) {
      setState(() => isStreamAvailable = false);
    }
  }

  Future<void> _openBluetoothPicker() async {
    final device = await Navigator.push<BluetoothDevice>(
      context,
      MaterialPageRoute(builder: (_) => const BluetoothDevicesPage()),
    );
    if (device == null) return;
    try {
      final conn = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _device = device;
        _connection = conn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name ?? device.address}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting: $e')),
      );
    }
  }

  void sendToArduino(String command) {
    if (_connection?.isConnected == true) {
      final data = Uint8List.fromList(utf8.encode('$command\n'));
      _connection!.output.add(data);
      _connection!.output.allSent.then((_) {
        debugPrint('Sent command: $command');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected')),
      );
    }
  }

  void _startRepeat(String command) {
    sendToArduino(command);
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      sendToArduino(command);
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  Widget holdableButton(IconData icon, String command) {
    return GestureDetector(
      onTapDown: (_) => _startRepeat(command),
      onTapUp: (_) => _stopRepeat(),
      onTapCancel: _stopRepeat,
      child: SizedBox(
        width: 60,
        height: 60,
        child: ElevatedButton(
          onPressed: () {}, // tap is handled by GestureDetector
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.blueGrey,
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 30),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final status = (_connection?.isConnected == true) ? 'Connected' : 'Ready';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade600, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          const Text('Status: ', style: TextStyle(color: Colors.white54)),
          Text(status, style: const TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: _connection?.isConnected == true ? 1.0 : 0.0,
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amphibian Boat Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: _openBluetoothPicker,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child:
            isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildStatusBar(),
        const SizedBox(height: 20),
        // Camera Feed
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.grey.shade600, width: 4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isStreamAvailable
              ? Mjpeg(
                  stream: streamUrl,
                  timeout: const Duration(seconds: 20),
                  isLive: true,
                  loading: (ctx) =>
                      const Center(child: CircularProgressIndicator()),
                  error: (ctx, error, stack) => Center(
                    child: Text(
                      'Stream Error:\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Stream not available',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _checkStream,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 40),
        // Control pad
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                holdableButton(Icons.arrow_drop_up, 'F'),
                Row(
                  children: [
                    holdableButton(Icons.arrow_left, 'L'),
                    const SizedBox(width: 60),
                    holdableButton(Icons.arrow_right, 'R'),
                  ],
                ),
                holdableButton(Icons.arrow_drop_down, 'B'),
              ],
            ),
            ElevatedButton(
              onPressed: () => sendToArduino('S'),
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
        _buildStatusBar(),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  holdableButton(Icons.arrow_drop_up, 'F'),
                  Row(
                    children: [
                      holdableButton(Icons.arrow_left, 'L'),
                      const SizedBox(width: 60),
                      holdableButton(Icons.arrow_right, 'R'),
                    ],
                  ),
                  holdableButton(Icons.arrow_drop_down, 'B'),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border:
                        Border.all(color: Colors.grey.shade600, width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isStreamAvailable
                      ? Mjpeg(
                          stream: streamUrl,
                          timeout: const Duration(seconds: 20),
                          isLive: true,
                          loading: (ctx) => const Center(
                              child: CircularProgressIndicator()),
                          error: (ctx, error, stack) => Center(
                            child: Text(
                              'Stream Error:\n$error',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Stream not available',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _checkStream,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => sendToArduino('S'),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(24),
                ),
                child: const Icon(Icons.construction, size: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
