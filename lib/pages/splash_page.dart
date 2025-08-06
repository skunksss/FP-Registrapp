import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drappnew/pages/home_page.dart'; // Página principal (si el usuario está autenticado)
import 'package:drappnew/pages/login_page.dart'; // Página de login (si no hay token)
import 'package:drappnew/services/logger.dart'; // Logger personalizado

/// Pantalla que se muestra al inicio para decidir si ir al login o al home.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _verificarToken(); // Comienza la verificación al cargar la pantalla
  }

  /// Verifica si existe un token guardado para decidir a qué pantalla ir
  Future<void> _verificarToken() async {
    // Simula carga por 2 segundos (puede ser para mostrar branding)
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      // Si hay token, se asume que la sesión sigue activa
      AppLogger.info("Token encontrado, redirigiendo a HomePage.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Si no hay token, se redirige a Login
      AppLogger.info("No hay token, redirigiendo a LoginPage.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 20),
            Text(
              'Cargando...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
