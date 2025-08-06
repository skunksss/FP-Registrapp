import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drappnew/services/logger.dart';

class AuthService {
  static const String baseUrl =
      'http://192.170.6.150:5000'; // Dirección del backend Flask
  static String? token; // Token en memoria

  /// Inicia sesión con RUT y password.
  /// Si es exitoso, guarda el token JWT en memoria y localmente con SharedPreferences.
  static Future<bool> login(String rut, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final body = jsonEncode({'rut': rut, 'password': password});

    AppLogger.info("Intentando iniciar sesión para RUT: $rut");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['access_token'];

        // Si el token es válido, lo guardamos
        if (token != null && token!.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token!);
          AppLogger.info("Token guardado exitosamente.");
          return true;
        } else {
          AppLogger.warning("Login exitoso pero token nulo o vacío.");
          return false;
        }
      } else {
        AppLogger.error(
          "Error en login: ${response.statusCode} ${response.body}",
        );
        return false;
      }
    } catch (e) {
      AppLogger.error("Excepción en login: $e");
      return false;
    }
  }

  /// Carga el token desde almacenamiento local (SharedPreferences) a memoria.
  static Future<void> cargarToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    AppLogger.info("Token cargado desde SharedPreferences: $token");
  }

  /// Cierra sesión:
  /// - Revoca el token llamando al backend.
  /// - Elimina el token de memoria y del almacenamiento local.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken == null) {
      AppLogger.warning("No hay token para cerrar sesión.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Authorization': 'Bearer $savedToken'},
      );

      if (response.statusCode == 200) {
        AppLogger.info("Logout exitoso en backend.");
      } else {
        AppLogger.warning(
          "Error en logout backend: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      AppLogger.error("Excepción al hacer logout en backend: $e");
    }

    token = null;
    await prefs.remove('token');
    AppLogger.info("Token eliminado de memoria y almacenamiento local.");
  }
}
