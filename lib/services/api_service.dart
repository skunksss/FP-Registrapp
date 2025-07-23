// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drappnew/services/logger.dart';

class ApiService {
  static const String baseUrl = 'http://192.170.6.150:5000'; // CAMBIA ESTO

  // Obtiene el token almacenado localmente
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtener historial filtrado
  static Future<List<dynamic>> getHistorial({
    String tipo = '',
    String? rutEmpresa,
    String? numeroGuia,
    String? fechaInicio,
    String? fechaFin,
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    String url = '$baseUrl/historial';
    if (tipo.isNotEmpty) url += '/$tipo';

    Map<String, String> params = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (rutEmpresa != null) params['rut_empresa'] = rutEmpresa;
    if (numeroGuia != null) params['numero_guia'] = numeroGuia;
    if (fechaInicio != null) params['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) params['fecha_fin'] = fechaFin;

    final uri = Uri.parse(url).replace(queryParameters: params);

    AppLogger.info("Llamando a la API: $uri");

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      AppLogger.info(
        "Historial obtenido exitosamente: ${data.length} elementos.",
      );
      if (tipo == 'despachos') {
        return data['despachos'];
      } else if (tipo == 'recepciones') {
        return data['recepciones'];
      } else {
        return data['movimientos'];
      }
    } else {
      AppLogger.error("Error al obtener historial: ${response.statusCode}");
      throw Exception('Error al obtener historial');
    }
  }

  // Obtener detalle de despacho o recepción por ID
  static Future<Map<String, dynamic>> obtenerDetalleMovimiento(
    String tipo,
    int id,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$baseUrl/$tipo/$id');
    AppLogger.info("Obteniendo detalle de movimiento ID: $id, tipo: $tipo");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      AppLogger.info("Detalle obtenido exitosamente para ID: $id");
      return json.decode(response.body);
    } else {
      AppLogger.error("Error al obtener el detalle: ${response.statusCode}");
      throw Exception('Error al obtener el detalle');
    }
  }
}
