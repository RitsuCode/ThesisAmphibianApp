// lib/controller_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'bluetooth_page.dart';

class AmphibianController extends StatefulWidget {
  const AmphibianController({Key? key}) : super(key: key);

  @override
  _AmphibianControllerState createState() => _AmphibianControllerState();
}

class _AmphibianControllerState extends State<AmphibianController> {
  static const _remoteView = 'http://193.214.77.234:8009/#view';
  static const _localStream = 'http://192.168.1.15:81/stream';
  String streamUrl = _remoteView;
  bool isStreamAvailable = false;

  BluetoothDevice? _device;
  BluetoothConnection? _connection;
  Timer? _repeatTimer;

  @override
  void initState() {
    super.initState();
    _warmUpAndSwitch();
    testHead();
    testRawHttp();
    checkNetwork();
  }

  Future<void> _warmUpAndSwitch() async {
    // 1) First try the remote view to activate the stream
    try {
      await http.get(Uri.parse(_remoteView))
          .timeout(const Duration(seconds: 3));
      debugPrint('Remote view activated');
    } catch (e) {
      debugPrint('Remote view activation failed: $e');
    }

    // 2) Switch to local stream after a brief delay
    await Future.delayed(const Duration(seconds: 10));
    setState(() => streamUrl = _localStream);
    debugPrint('Local view activated');
    // 3) Verify the local stream

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
          .get(
            Uri.parse(streamUrl),
            headers: {'Range': 'bytes=0-10'}
          )
          .timeout(const Duration(seconds: 5));

      setState(() => isStreamAvailable =
          (resp.statusCode == 200 || resp.statusCode == 206));
    } catch (_) {
      setState(() => isStreamAvailable = false);
    }
  }

  Future<void> testHead() async {
    try {
      final res = await http
        .head(Uri.parse(_remoteView))
        .timeout(const Duration(seconds: 5));
      debugPrint('🟢 HEAD status: ${res.statusCode}');
    } catch (e) {
      debugPrint('🔴 HEAD error: $e');
    }
  }

  Future<void> testRawHttp() async {
    try {
      final resp = await http
        .get(
          Uri.parse(_remoteView),
          headers: {'Range': 'bytes=0-20'},
        )
        .timeout(const Duration(seconds: 5));
      debugPrint('🟢 HTTP STATUS: ${resp.statusCode}');
      debugPrint('🟢 BYTES: ${resp.bodyBytes.take(10).toList()}');
    } catch (e) {
      debugPrint('🔴 HTTP ERROR: $e');
    }
  }

  Future<void> checkNetwork() async {
    final conn = await Connectivity().checkConnectivity();
    switch (conn) {
      case ConnectivityResult.wifi:
        debugPrint('✅ Connected over Wi-Fi');
        break;
      case ConnectivityResult.mobile:
        debugPrint('⚠️ Connected over Mobile Data');
        break;
      case ConnectivityResult.none:
        debugPrint('❌ No network connection');
        break;
      default:
        debugPrint('🔍 Unknown connectivity status');
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
          onPressed: () {},
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
    final isConnected = _connection?.isConnected == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Tooltip(
            message: isConnected 
                ? 'Connected to ${_device?.name ?? _device?.address}' 
                : 'Disconnected',
            child: Icon(
              Icons.bluetooth,
              color: isConnected ? Colors.blue : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: isStreamAvailable ? 'Stream available' : 'Stream unavailable',
            child: Icon(
              Icons.videocam,
              color: isStreamAvailable ? Colors.green : Colors.grey,
              size: 24,
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
        child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildStatusBar(),
        const SizedBox(height: 20),
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => sendToArduino('U'),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(Icons.arrow_upward, size: 30),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => sendToArduino('D'),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(Icons.arrow_downward, size: 30),
                ),
              ],
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
                    border: Border.all(color: Colors.grey.shade600, width: 4),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => sendToArduino('U'),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(Icons.arrow_upward, size: 30),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => sendToArduino('D'),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(Icons.arrow_downward, size: 30),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}