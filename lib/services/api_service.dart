import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drappnew/services/logger.dart';

class ApiService {
  static const String baseUrl = 'http://192.170.6.150:5000';

  // Obtiene el token almacenado localmente
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtener historial filtrado y paginado
  static Future<Map<String, dynamic>> getHistorial({
    String tipo = '',
    String? rutEmpresa,
    String? numeroGuia,
    String? fechaInicio,
    String? fechaFin,
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      AppLogger.error(
        'Token no encontrado. El usuario debe volver a iniciar sesión.',
      );
      throw Exception('Token no encontrado. Autenticación requerida.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    String url = '$baseUrl/historial';
    if (tipo.isNotEmpty && tipo != 'movimientos') {
      url += '/$tipo';
    }

    Map<String, String> params = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (rutEmpresa != null && rutEmpresa.isNotEmpty) {
      params['rut_empresa'] = rutEmpresa;
    }
    if (numeroGuia != null && numeroGuia.isNotEmpty) {
      params['numero_guia'] = numeroGuia;
    }
    if (fechaInicio != null && fechaInicio.isNotEmpty) {
      params['fecha_inicio'] = fechaInicio;
    }
    if (fechaFin != null && fechaFin.isNotEmpty) {
      params['fecha_fin'] = fechaFin;
    }

    final uri = Uri.parse(url).replace(queryParameters: params);

    AppLogger.info("Llamando a la API: $uri");

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      AppLogger.info("Historial obtenido exitosamente.");
      return data;
    } else {
      AppLogger.error(
        "Error al obtener historial: ${response.statusCode} ${response.body}",
      );
      throw Exception('Error al obtener historial');
    }
  }

  // Obtener detalle de despacho o recepción por ID
  static Future<Map<String, dynamic>> obtenerDetalleMovimiento(
    String tipo,
    int id,
  ) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      AppLogger.error(
        'Token no encontrado. El usuario debe volver a iniciar sesión.',
      );
      throw Exception('Token no encontrado. Autenticación requerida.');
    }

    AppLogger.debug('Token usado para detalle: $token');

    String endpoint;
    if (tipo == 'despachos' || tipo == 'despacho') {
      endpoint = '/detalle/despacho/$id';
    } else if (tipo == 'recepciones' || tipo == 'recepcion') {
      endpoint = '/detalle/recepcion/$id';
    } else {
      throw Exception('Tipo de movimiento no válido');
    }

    final url = Uri.parse('$baseUrl$endpoint');
    AppLogger.info("Obteniendo detalle de movimiento ID: $id, tipo: $tipo");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      AppLogger.info("Detalle obtenido exitosamente para ID: $id");
      return data;
    } else {
      AppLogger.error(
        "Error al obtener el detalle: ${response.statusCode} ${response.body}",
      );
      throw Exception('Error al obtener el detalle');
    }
  }
}
