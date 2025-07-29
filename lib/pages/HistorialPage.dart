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
  List movimientos = [];
  int currentPage = 1;
  int totalPages = 1;
  String tipo = 'movimientos';
  String searchText = '';
  String ordenamiento = 'Ordenar por';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHistorial();
  }

  Future<void> fetchHistorial() async {
    String baseUrl;
    if (tipo == 'despachos') {
      baseUrl = 'http://192.170.6.150:5000/historial/despachos';
    } else if (tipo == 'recepciones') {
      baseUrl = 'http://192.170.6.150:5000/historial/recepciones';
    } else {
      baseUrl =
          'http://192.170.6.150:5000/historial'; // Esta URL debe existir en Flask
    }

    final params = {
      'page': currentPage.toString(),
      'per_page': '10',
      if (searchText.isNotEmpty) 'numero_guia': searchText,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final token = AuthService.token ?? '';
    AppLogger.info("Cargando historial de tipo: $tipo, página: $currentPage");

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
      AppLogger.info(
        "Historial cargado exitosamente: ${movimientos.length} movimientos encontrados.",
      );
    } else {
      AppLogger.error(
        "Error al obtener historial: ${response.statusCode} - ${response.body}",
      );
      setState(() {
        movimientos = [];
      });
    }
  }

  void cambiarTipo(String nuevoTipo) {
    setState(() {
      tipo = nuevoTipo;
      currentPage = 1;
    });
    fetchHistorial();
  }

  void siguientePagina() {
    if (currentPage < totalPages) {
      setState(() => currentPage++);
      fetchHistorial();
    }
  }

  void paginaAnterior() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchHistorial();
    }
  }

  void ordenarMovimientos(String criterio) {
    setState(() {
      ordenamiento = criterio;
      if (criterio == 'Fecha Ascendente') {
        movimientos.sort((a, b) => a['fecha'].compareTo(b['fecha']));
      } else if (criterio == 'Fecha Descendente') {
        movimientos.sort((a, b) => b['fecha'].compareTo(a['fecha']));
      } else if (criterio == 'RUT Ascendente') {
        movimientos.sort(
          (a, b) => a['rut_empresa'].compareTo(b['rut_empresa']),
        );
      } else if (criterio == 'RUT Descendente') {
        movimientos.sort(
          (a, b) => b['rut_empresa'].compareTo(a['rut_empresa']),
        );
      }
    });
  }

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
            _buildSearchAndFilters(),
            SizedBox(height: 10),
            _buildTipoSelector(),
            SizedBox(height: 10),
            _buildListaMovimientos(),
            _buildPaginacion(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                searchText = _searchController.text.trim();
                currentPage = 1;
              });
              fetchHistorial();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_alt, color: Colors.white),
            onSelected: ordenarMovimientos,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'Fecha Ascendente',
                child: Text('Fecha Ascendente'),
              ),
              PopupMenuItem(
                value: 'Fecha Descendente',
                child: Text('Fecha Descendente'),
              ),
              PopupMenuItem(
                value: 'RUT Ascendente',
                child: Text('RUT Ascendente'),
              ),
              PopupMenuItem(
                value: 'RUT Descendente',
                child: Text('RUT Descendente'),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
