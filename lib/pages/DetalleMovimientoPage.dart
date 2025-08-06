import 'dart:typed_data'; // Para trabajar con bytes de imágenes.
import 'package:flutter/material.dart';
import 'package:drappnew/services/api_service.dart'; // Servicio para obtener detalle del movimiento.
import 'package:drappnew/services/logger.dart'; // Sistema de logs.
import 'package:http/http.dart' as http; // Peticiones HTTP.
import 'package:shared_preferences/shared_preferences.dart'; // Acceso al token guardado localmente.

// Pantalla que muestra el detalle de un despacho o recepción.
class DetalleMovimientoPage extends StatefulWidget {
  final String tipo; // Puede ser 'despachos' o 'recepciones'
  final int id; // ID del movimiento

  const DetalleMovimientoPage({
    super.key,
    required this.tipo,
    required this.id,
  });

  @override
  State<DetalleMovimientoPage> createState() => _DetalleMovimientoPageState();
}

class _DetalleMovimientoPageState extends State<DetalleMovimientoPage> {
  // Futuro que traerá los datos del movimiento al iniciar
  late Future<Map<String, dynamic>> _detalleFuture;

  @override
  void initState() {
    super.initState();
    _detalleFuture = ApiService.obtenerDetalleMovimiento(
      widget.tipo,
      widget.id,
    );

    AppLogger.info(
      "Cargando detalles del movimiento ID: ${widget.id} de tipo: ${widget.tipo}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Historial', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _detalleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              AppLogger.error("Error al cargar detalles: ${snapshot.error}");
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final data = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información general
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'RUT: ${data['rut_empresa']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'N° guía: ${data['numero_guia']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Fecha: ${data['fecha']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Galería de fotos por tipo
                          _buildMultipleFotos(
                            'Carnet',
                            data['fotos_carnet_urls'],
                          ),
                          const SizedBox(height: 16),
                          _buildMultipleFotos(
                            'Patente',
                            data['fotos_patente_urls'],
                          ),
                          const SizedBox(height: 16),
                          _buildMultipleFotos(
                            'Carga',
                            data['fotos_carga_urls'],
                          ),
                          const SizedBox(height: 16),

                          // Observación de la carga (si existe)
                          if (data['observacion'] != null &&
                              data['observacion'].toString().trim().isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Observación sobre la carga:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['observacion'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Muestra múltiples imágenes en carrusel horizontal
  Widget _buildMultipleFotos(String tipo, List<dynamic>? urls) {
    if (urls == null || urls.isEmpty) {
      // Si no hay fotos, muestra un ícono indicando la falta de imagen
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto $tipo:', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            height: 120,
            color: Colors.white,
            child: const Center(child: Icon(Icons.image_not_supported)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos $tipo:', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            itemBuilder: (context, index) {
              final url = urls[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      // Imagen protegida por token
                      Expanded(
                        child: FutureBuilder<Uint8List?>(
                          future: _fetchProtectedImage(url),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError ||
                                snapshot.data == null) {
                              return const Center(
                                child: Icon(Icons.broken_image),
                              );
                            } else {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Botón para ver imagen ampliada
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _verImagen(url),
                          child: const Text(
                            'VER',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Descarga una imagen protegida usando token JWT desde SharedPreferences
  Future<Uint8List?> _fetchProtectedImage(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }

  // Abre pantalla nueva para ver imagen ampliada
  void _verImagen(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Vista de Imagen')),
          body: FutureBuilder<Uint8List?>(
            future: _fetchProtectedImage(url),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Icon(Icons.broken_image));
              } else {
                return Center(child: Image.memory(snapshot.data!));
              }
            },
          ),
        ),
      ),
    );
  }
}
