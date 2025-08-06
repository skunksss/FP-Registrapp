import 'package:flutter/material.dart';
import 'package:drappnew/services/logger.dart'; // Servicio de logging centralizado
import 'package:drappnew/services/auth_service.dart'; // Servicio de autenticación
import 'package:drappnew/pages/splash_page.dart'; // Página de inicio (splash screen)

void main() async {
  // Asegura que Flutter esté inicializado antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Log inicial para rastrear inicio de app
  AppLogger.info("Aplicación iniciando...");

  // Cargar token desde almacenamiento local para mantener sesión
  await AuthService.cargarToken();

  // Iniciar la aplicación
  runApp(const MyApp());
}

/// Widget raíz de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Despachos', // Nombre que se muestra en multitarea
      debugShowCheckedModeBanner: false, // Elimina la cinta de debug
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Habilita Material Design 3
      ),
      home:
          const SplashPage(), // Página inicial que decide a dónde redirigir (login o inicio)
    );
  }
}
