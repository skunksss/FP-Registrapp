// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'services/logger.dart';

void main() {
  AppLogger.info("Aplicación iniciando...");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Despachos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LoginPage(),
    );
  }
}
