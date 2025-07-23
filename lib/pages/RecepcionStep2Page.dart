// lib/pages/RecepcionStep2Page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:drappnew/services/auth_service.dart';
import 'dart:convert';
import 'package:drappnew/services/logger.dart';

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
  File? carnetImage;
  File? patenteImage;
  File? cargaImage;

  final picker = ImagePicker();

  Future<File?> pickCompressedImage() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    final mediaStatus = await Permission.photos.request();

    if (!cameraStatus.isGranted ||
        (!storageStatus.isGranted && !mediaStatus.isGranted)) {
      AppLogger.warning("Permisos no concedidos para cámara o almacenamiento");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permisos no concedidos')));
      return null;
    }

    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (picked == null) return null;

    AppLogger.info("Imagen seleccionada: ${picked.path}");
    return File(picked.path);
  }

  Future<void> _pickImage(Function(File) onPicked) async {
    final image = await pickCompressedImage();
    if (image != null) {
      onPicked(image);
    }
  }

  Future<int?> crearRecepcion() async {
    final uri = Uri.parse('http://192.170.6.150/recepciones/');
    final request = http.MultipartRequest('POST', uri)
      ..fields['numero_guia'] = widget.numeroGuia
      ..fields['rut_empresa'] = widget.rutEmpresa
      ..headers['Authorization'] = 'Bearer ${AuthService.token}';

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final json = jsonDecode(responseBody);
        AppLogger.info("Recepción creada con ID: ${json['id']}");
        return json['id'];
      } else {
        AppLogger.error("Error al crear recepción: $responseBody");
      }
    } catch (e) {
      AppLogger.error("Excepción al crear recepción: $e");
    }
    return null;
  }

  Future<void> subirFoto({
    required int recepcionId,
    required File imagen,
    required String tipo,
  }) async {
    final uri = Uri.parse(
      'http://192.170.6.150:5000/recepciones/$recepcionId/fotos',
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${AuthService.token}'
      ..fields['tipo'] = tipo
      ..files.add(await http.MultipartFile.fromPath('archivo', imagen.path));

    try {
      final response = await request.send();
      final res = await response.stream.bytesToString();
      if (response.statusCode != 201) {
        AppLogger.error("Error al subir foto $tipo: $res");
      } else {
        AppLogger.info("Foto $tipo subida exitosamente");
      }
    } catch (e) {
      AppLogger.error("Excepción al subir foto $tipo: $e");
    }
  }

  void _guardarYRecepcionar() async {
    if (carnetImage == null || patenteImage == null || cargaImage == null) {
      AppLogger.warning("Intento de guardar recepción sin todas las fotos");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes tomar las 3 fotos')));
      return;
    }

    final recepcionId = await crearRecepcion();
    if (recepcionId == null) {
      AppLogger.error("Error al crear recepción");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al crear recepción')));
      return;
    }

    await subirFoto(
      recepcionId: recepcionId,
      imagen: carnetImage!,
      tipo: 'carnet',
    );
    await subirFoto(
      recepcionId: recepcionId,
      imagen: patenteImage!,
      tipo: 'patente',
    );
    await subirFoto(
      recepcionId: recepcionId,
      imagen: cargaImage!,
      tipo: 'carga',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recepción guardada exitosamente')),
    );

    AppLogger.info("Recepción guardada exitosamente con ID: $recepcionId");
    Navigator.pop(context);
  }

  Widget buildFotoBox({
    required String label,
    required File? imageFile,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          TextField(
            readOnly: true,
            controller: TextEditingController(
              text: imageFile != null ? imageFile.path.split('/').last : '',
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ABRIR CÁMARA'),
            ),
          ),
        ],
      ),
    );
  }

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
          children: [
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
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RUT Empresa: ${widget.rutEmpresa}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            buildFotoBox(
              label: 'Tomar foto carnet:',
              imageFile: carnetImage,
              onPressed: () =>
                  _pickImage((file) => setState(() => carnetImage = file)),
            ),
            buildFotoBox(
              label: 'Tomar foto patente:',
              imageFile: patenteImage,
              onPressed: () =>
                  _pickImage((file) => setState(() => patenteImage = file)),
            ),
            buildFotoBox(
              label: 'Tomar foto carga:',
              imageFile: cargaImage,
              onPressed: () =>
                  _pickImage((file) => setState(() => cargaImage = file)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarYRecepcionar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar y recepcionar',
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
