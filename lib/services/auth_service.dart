import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:5000'; // Flask local
  static String? token;

  static Future<bool> login(String rut, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final body = jsonEncode({'rut': rut, 'password': password});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['access_token'];
        print('Token recibido: $token');
        return true;
      } else {
        print('Error login: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en login: $e');
      return false;
    }
  }
}
