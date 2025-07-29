// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drappnew/services/logger.dart';

class AuthService {
  static const String baseUrl = 'http://192.170.6.150:5000'; // Flask local
  static String? token;

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

        if (token != null && token!.isNotEmpty) {
          // Guardar el token en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token!);

          AppLogger.info("Token guardado en SharedPreferences: $token");
          return true;
        } else {
          AppLogger.warning("Login exitoso, pero token vacío o nulo.");
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
}
