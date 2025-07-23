// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
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
        AppLogger.info("Token recibido: $token");
        return true;
      } else {
        AppLogger.error("Error en login: ${response.body}");
        return false;
      }
    } catch (e) {
      AppLogger.error("Excepción en login: $e");
      return false;
    }
  }
}
