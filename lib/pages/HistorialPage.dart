import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'DetalleMovimientoPage.dart';
import 'package:drappnew/services/logger.dart';
import 'package:drappnew/services/auth_service.dart';

class HistorialPage extends StatefulWidget {
  @override
  _HistorialPageState createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  List movimientos = []; // Lista de movimientos obtenidos desde el backend
  int currentPage = 1;
  int totalPages = 1;
  String tipo =
      'movimientos'; // Puede ser 'despachos', 'recepciones' o 'movimientos'

  // Variables de filtro
  String numeroGuia = '';
  String rutEmpresa = '';
  String fechaInicio = '';
  String fechaFin = '';

  // Controladores para los campos de búsqueda
  final TextEditingController _guiaController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHistorial(); // Carga inicial
  }

  // Función que hace la solicitud HTTP al backend según el tipo y filtros
  Future<void> fetchHistorial() async {
    String baseUrl;
    if (tipo == 'despachos') {
      baseUrl = 'http://192.170.6.150:5000/historial/despachos';
    } else if (tipo == 'recepciones') {
      baseUrl = 'http://192.170.6.150:5000/historial/recepciones';
    } else {
      baseUrl = 'http://192.170.6.150:5000/historial';
    }

    // Armado de parámetros de búsqueda
    final params = {
      'page': currentPage.toString(),
      'per_page': '10',
      if (numeroGuia.isNotEmpty) 'numero_guia': numeroGuia,
      if (rutEmpresa.isNotEmpty) 'rut_empresa': rutEmpresa,
      if (fechaInicio.isNotEmpty) 'fecha_inicio': fechaInicio,
      if (fechaFin.isNotEmpty) 'fecha_fin': fechaFin,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final token = AuthService.token ?? '';

    AppLogger.info("Cargando historial de tipo: $tipo, página: $currentPage");

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          movimientos = tipo == 'despachos'
              ? data['despachos']
              : tipo == 'recepciones'
              ? data['recepciones']
              : data['movimientos'];
          totalPages = data['pages'];
          currentPage = data['current_page'];
        });

        AppLogger.info("Historial cargado exitosamente.");
      } else {
        AppLogger.error(
          "Error al obtener historial: ${response.statusCode} - ${response.body}",
        );
        setState(() => movimientos = []);
      }
    } catch (e) {
      AppLogger.error("Excepción al obtener historial: $e");
      setState(() => movimientos = []);
    }
  }

  // Cambia el tipo (despacho, recepción, movimientos) y reinicia la página
  void cambiarTipo(String nuevoTipo) {
    setState(() {
      tipo = nuevoTipo;
      currentPage = 1;
    });
    fetchHistorial();
  }

  // Cambia a la siguiente página
  void siguientePagina() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
      fetchHistorial();
    }
  }

  // Cambia a la página anterior
  void paginaAnterior() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchHistorial();
    }
  }

  // INTERFAZ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(
          'Historial',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchFields(), // Filtros de búsqueda
            SizedBox(height: 10),
            _buildTipoSelector(), // Botones de tipo de historial
            SizedBox(height: 10),
            _buildListaMovimientos(), // Lista de resultados
            _buildPaginacion(), // Navegación entre páginas
          ],
        ),
      ),
    );
  }

  // Construye los campos de búsqueda
  Widget _buildSearchFields() {
    return Column(
      children: [
        _buildInput(_guiaController, 'Buscar por número de guía'),
        SizedBox(height: 8),
        _buildInput(_rutController, 'Buscar por RUT empresa'),
        SizedBox(height: 8),
        _buildInput(_fechaInicioController, 'Fecha inicio (YYYY-MM-DD)'),
        SizedBox(height: 8),
        _buildInput(_fechaFinController, 'Fecha fin (YYYY-MM-DD)'),
        SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          icon: Icon(Icons.search),
          label: Text('Buscar'),
          onPressed: () {
            setState(() {
              numeroGuia = _guiaController.text.trim();
              rutEmpresa = _rutController.text.trim();
              fechaInicio = _fechaInicioController.text.trim();
              fechaFin = _fechaFinController.text.trim();
              currentPage = 1;
            });
            fetchHistorial();
          },
        ),
      ],
    );
  }

  // Campo de texto reutilizable
  Widget _buildInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Selector de tipo de historial
  Widget _buildTipoSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTipoButton('despachos', 'Despacho'),
        SizedBox(width: 10),
        _buildTipoButton('recepciones', 'Recepción'),
        SizedBox(width: 10),
        _buildTipoButton('movimientos', 'Todos'),
      ],
    );
  }

  // Botón de tipo
  Widget _buildTipoButton(String tipoValor, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: tipo == tipoValor ? Colors.amber : Colors.grey,
        foregroundColor: Colors.black,
      ),
      onPressed: () => cambiarTipo(tipoValor),
      child: Text(label),
    );
  }

  // Lista de movimientos obtenidos del backend
  Widget _buildListaMovimientos() {
    if (movimientos.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No hay movimientos para mostrar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: movimientos.length,
        itemBuilder: (context, index) {
          final mov = movimientos[index];

          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Información básica del movimiento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RUT: ${mov['rut_empresa']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Nº guía: ${mov['numero_guia']}'),
                      Text(
                        'Fecha: ${DateTime.parse(mov['fecha']).toLocal().toString().substring(0, 10)}',
                      ),
                    ],
                  ),
                ),
                // Botón para ver el detalle del movimiento
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('VER'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleMovimientoPage(
                          id: mov['id'],
                          tipo: tipo == 'movimientos' ? mov['tipo'] : tipo,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Paginación: anterior y siguiente
  Widget _buildPaginacion() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: paginaAnterior,
          child: Text('Anterior', style: TextStyle(color: Colors.amber)),
        ),
        Text(
          'Página $currentPage de $totalPages',
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: siguientePagina,
          child: Text('Siguiente', style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }
}
