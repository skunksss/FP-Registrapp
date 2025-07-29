// lib/main.dart
import 'package:flutter/material.dart';
import 'package:drappnew/services/logger.dart';
import 'package:drappnew/pages/splash_page.dart';

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
      home: const SplashPage(), // <<--- Ahora empieza en Splash
    );
  }
}
