import 'dart:io'; // Para manejar archivos locales, como las fotos.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para capturar imágenes.
import 'package:permission_handler/permission_handler.dart'; // Para solicitar permisos de cámara y almacenamiento.
import 'package:http/http.dart' as http; // Para enviar peticiones HTTP.
import 'package:drappnew/services/auth_service.dart'; // Servicio personalizado que maneja el token JWT.
import 'dart:convert'; // Para decodificar respuestas JSON.
import 'package:drappnew/services/logger.dart'; // Sistema de logs para registrar eventos.

// Página donde se toman y suben fotos para crear un despacho.
class DespachoStep2Page extends StatefulWidget {
  final String numeroGuia; // Número de guía del despacho.
  final String rutEmpresa; // RUT de la empresa asociada.

  const DespachoStep2Page({
    super.key,
    required this.numeroGuia,
    required this.rutEmpresa,
  });

  @override
  State<DespachoStep2Page> createState() => _DespachoStep2PageState();
}

class _DespachoStep2PageState extends State<DespachoStep2Page> {
  // Variables para almacenar temporalmente las fotos
  File? carnetImage;
  File? patenteImage;
  File? cargaImage;

  // Controlador del campo de observación de la carga
  final TextEditingController _observacionController = TextEditingController();

  final picker = ImagePicker(); // Instancia para capturar imágenes

  // Función que pide permisos y abre la cámara para tomar una imagen comprimida
  Future<File?> pickCompressedImage() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    final mediaStatus = await Permission.photos.request();

    // Si no se otorgan los permisos, se muestra advertencia y se cancela la acción
    if (!cameraStatus.isGranted ||
        (!storageStatus.isGranted && !mediaStatus.isGranted)) {
      AppLogger.warning("Permisos no concedidos para cámara o almacenamiento");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permisos no concedidos')));
      return null;
    }

    // Abre la cámara para capturar imagen
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60, // Comprime la imagen
      maxWidth: 800,
      maxHeight: 800,
    );

    if (picked == null) return null;

    AppLogger.info("Imagen seleccionada: ${picked.path}");
    return File(picked.path);
  }

  // Método genérico que recibe una función callback para manejar la imagen seleccionada
  Future<void> _pickImage(Function(File) onPicked) async {
    final image = await pickCompressedImage();
    if (image != null) {
      onPicked(image);
    }
  }

  // Crea el despacho en el backend y devuelve su ID
  Future<int?> crearDespacho() async {
    final uri = Uri.parse('http://192.170.6.150:5000/despachos/');
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
        AppLogger.info("Despacho creado con ID: ${json['id']}");
        return json['id'];
      } else {
        AppLogger.error("Error al crear despacho: $responseBody");
      }
    } catch (e) {
      AppLogger.error("Excepción al crear despacho: $e");
    }
    return null;
  }

  // Sube una imagen a un despacho ya creado
  Future<void> subirFoto({
    required int despachoId,
    required File imagen,
    required String tipo,
  }) async {
    final uri = Uri.parse(
      'http://192.170.6.150:5000/despachos/$despachoId/fotos',
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

  // Función que se ejecuta al presionar "Guardar y despachar"
  void _guardarYDespachar() async {
    // Verifica que se hayan tomado todas las fotos
    if (carnetImage == null || patenteImage == null || cargaImage == null) {
      AppLogger.warning("Intento de guardar despacho sin todas las fotos");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes tomar las 3 fotos')));
      return;
    }

    final despachoId = await crearDespacho();
    if (despachoId == null) {
      AppLogger.error("Error al crear despacho");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al crear despacho')));
      return;
    }

    // Sube las fotos al backend
    await subirFoto(
      despachoId: despachoId,
      imagen: carnetImage!,
      tipo: 'carnet',
    );
    await subirFoto(
      despachoId: despachoId,
      imagen: patenteImage!,
      tipo: 'patente',
    );
    await subirFoto(despachoId: despachoId, imagen: cargaImage!, tipo: 'carga');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Despacho guardado exitosamente')),
    );
    AppLogger.info("Despacho guardado exitosamente con ID: $despachoId");

    Navigator.pop(context); // Regresa a la pantalla anterior
  }

  // Widget que construye el cuadro de captura de imagen
  Widget buildFotoBox({
    required String label,
    required File? imageFile,
    required VoidCallback onPressed,
    bool incluirObservacion = false,
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
          // Muestra el nombre del archivo de imagen
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
          // Solo se muestra en la foto de carga
          if (incluirObservacion) ...[
            const SizedBox(height: 20),
            const Text(
              'Observación sobre la carga:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                hintText: 'Ej: Carga mal embalada, caja rota...',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Interfaz de usuario principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: const Text(
          'Despacho',
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
            // Muestra la guía y el RUT
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
            // Módulos de captura de imagen
            buildFotoBox(
              label: 'Tomar foto cédula de identidad:',
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
              incluirObservacion: true,
            ),
            const SizedBox(height: 10),
            // Botón final para guardar todo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarYDespachar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar y despachar',
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
