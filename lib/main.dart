import 'package:flutter/material.dart';
import 'controller_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino GameBoy Controller',
      theme: ThemeData.dark(),
      home: const AmphibianController(),
    );
  }
}
