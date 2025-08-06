import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para capturar imágenes con la cámara.
import 'package:permission_handler/permission_handler.dart'; // Para solicitar permisos de cámara/almacenamiento.
import 'package:http/http.dart' as http; // Para enviar solicitudes HTTP.
import 'package:drappnew/services/auth_service.dart'; // Para obtener el token JWT.
import 'dart:convert'; // Para decodificar JSON.
import 'package:drappnew/services/logger.dart'; // Sistema de logs personalizados.

// Página para completar la recepción: fotos + observación
class RecepcionStep2Page extends StatefulWidget {
  final String numeroGuia;
  final String rutEmpresa;

  const RecepcionStep2Page({
    super.key,
    required this.numeroGuia,
    required this.rutEmpresa,
  });

  @override
  State<RecepcionStep2Page> createState() => _RecepcionStep2PageState();
}

class _RecepcionStep2PageState extends State<RecepcionStep2Page> {
  // Listas para almacenar múltiples fotos por tipo
  final List<File> carnetFotos = [];
  final List<File> patenteFotos = [];
  final List<File> cargaFotos = [];

  final TextEditingController _observacionController = TextEditingController();
  final picker = ImagePicker();

  // Abre la cámara y captura imagen comprimida
  Future<File?> pickCompressedImage() async {
    // Solicita permisos necesarios
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    final mediaStatus = await Permission.photos.request();

    // Si faltan permisos, se notifica al usuario
    if (!cameraStatus.isGranted ||
        (!storageStatus.isGranted && !mediaStatus.isGranted)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permisos no concedidos')));
      return null;
    }

    // Captura imagen desde cámara
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

  // Agrega una foto a la lista si no ha superado el límite
  Future<void> agregarFoto(List<File> lista, int maxFotos) async {
    if (lista.length >= maxFotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo $maxFotos fotos permitidas')),
      );
      return;
    }

    final image = await pickCompressedImage();
    if (image != null) {
      setState(() => lista.add(image));
    }
  }

  // Crea la recepción en el backend y devuelve su ID
  Future<int?> crearRecepcion() async {
    final uri = Uri.parse('http://192.170.6.150:5000/recepciones/');
    final request = http.MultipartRequest('POST', uri)
      ..fields['numero_guia'] = widget.numeroGuia
      ..fields['rut_empresa'] = widget.rutEmpresa
      ..fields['observacion'] = _observacionController.text
      ..headers['Authorization'] = 'Bearer ${AuthService.token}';

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final json = jsonDecode(responseBody);
        return json['id'];
      }
    } catch (_) {
      // Puedes loggear la excepción si deseas
    }
    return null;
  }

  // Sube fotos al backend para un tipo específico (carnet, patente, carga)
  Future<void> subirFotos({
    required int recepcionId,
    required List<File> fotos,
    required String tipo,
  }) async {
    if (fotos.isEmpty) return;

    final uri = Uri.parse(
      'http://192.170.6.150:5000/recepciones/$recepcionId/fotos',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${AuthService.token}'
      ..fields['tipo'] = tipo;

    // Agrega cada archivo a la petición
    for (var f in fotos) {
      request.files.add(await http.MultipartFile.fromPath('archivo', f.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode != 201) {
        final res = await response.stream.bytesToString();
        AppLogger.error("Error al subir $tipo: $res");
      }
    } catch (e) {
      AppLogger.error("Excepción al subir $tipo: $e");
    }
  }

  // Función principal al presionar "Guardar y recibir"
  void _guardarYRecibir() async {
    // Verifica que se hayan tomado todas las fotos requeridas
    if (carnetFotos.length != 2 ||
        patenteFotos.length != 1 ||
        cargaFotos.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes completar las fotos requeridas')),
      );
      return;
    }

    final id = await crearRecepcion();
    if (id == null) return;

    await subirFotos(recepcionId: id, fotos: carnetFotos, tipo: 'carnet');
    await subirFotos(recepcionId: id, fotos: patenteFotos, tipo: 'patente');
    await subirFotos(recepcionId: id, fotos: cargaFotos, tipo: 'carga');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Recepción registrada con éxito')));
    Navigator.pop(context); // Vuelve a la pantalla anterior
  }

  // Componente visual para mostrar galería de fotos con opción de eliminar
  Widget buildGaleria(String tipo, List<File> fotos, int maxFotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos de $tipo (${fotos.length}/$maxFotos):',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: fotos.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Stack(
              children: [
                Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => fotos.removeAt(index)),
                    child: Container(
                      color: Colors.black54,
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => agregarFoto(fotos, maxFotos),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
          ),
          child: const Text("Tomar Foto"),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Interfaz visual principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text(
          'Recepción',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Muestra número de guía y RUT empresa
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Número de Guía: ${widget.numeroGuia}',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RUT Empresa: ${widget.rutEmpresa}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            // Galerías por tipo
            buildGaleria('carnet', carnetFotos, 2),
            buildGaleria('patente', patenteFotos, 1),
            buildGaleria('carga', cargaFotos, 4),
            const SizedBox(height: 10),

            // Observación de la carga
            const Text('Observación:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                hintText: 'Ej: Caja dañada, carga suelta...',
              ),
            ),
            const SizedBox(height: 20),

            // Botón para guardar todo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarYRecibir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar y recibir',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
