import 'package:flutter/material.dart';
import 'package:drappnew/services/api_service.dart';

class DetalleMovimientoPage extends StatefulWidget {
  final String tipo;
  final int id;

  const DetalleMovimientoPage({
    super.key,
    required this.tipo,
    required this.id,
  });

  @override
  State<DetalleMovimientoPage> createState() => _DetalleMovimientoPageState();
}

class _DetalleMovimientoPageState extends State<DetalleMovimientoPage> {
  late Future<Map<String, dynamic>> _detalleFuture;

  @override
  void initState() {
    super.initState();
    _detalleFuture = ApiService.obtenerDetalleMovimiento(
      widget.tipo,
      widget.id,
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detalleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
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
                    _buildFotoItem('Carnet', data['foto_carnet_url']),
                    const SizedBox(height: 16),
                    _buildFotoItem('Patente', data['foto_patente_url']),
                    const SizedBox(height: 16),
                    _buildFotoItem('Carga', data['foto_carga_url']),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFotoItem(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto $label:', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Container(
          color: Colors.white,
          height: 120,
          width: double.infinity,
          child: url != null
              ? Image.network(url, fit: BoxFit.cover)
              : const Center(child: Icon(Icons.image_not_supported)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: url != null ? () => _verImagen(url) : null,
            child: const Text('VER'),
          ),
        ),
      ],
    );
  }

  void _verImagen(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Vista de Imagen')),
          body: Center(child: Image.network(url)),
        ),
      ),
    );
  }
}
