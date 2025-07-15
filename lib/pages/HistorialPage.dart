import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DetalleMovimientoPage.dart'; // debes crear esta página luego

class HistorialPage extends StatefulWidget {
  @override
  _HistorialPageState createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  List movimientos = [];
  int currentPage = 1;
  int totalPages = 1;
  String tipo =
      'movimientos'; // Cambiado a 'movimientos' para mostrar ambos por defecto
  String searchText = '';
  String ordenamiento = 'Ordenar por'; // Texto inicial del filtro

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHistorial(); // Cargar historial al iniciar
  }

  Future<void> fetchHistorial() async {
    final uri = Uri.parse(
      tipo == 'despachos'
          ? 'https://tu-backend.com/historial/despachos?page=$currentPage&numero_guia=$searchText'
          : tipo == 'recepciones'
          ? 'https://tu-backend.com/historial/recepciones?page=$currentPage&numero_guia=$searchText'
          : 'https://tu-backend.com/historial/?page=$currentPage&numero_guia=$searchText',
    );
    final token =
        'AQUI_TU_TOKEN_JWT'; // reemplace con lógica desde SharedPreferences

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
    } else {
      print('Error al obtener historial');
    }
  }

  void cambiarTipo(String nuevoTipo) {
    setState(() {
      tipo = nuevoTipo;
      currentPage = 1; // Reiniciar a la primera página
    });
    fetchHistorial(); // Llamar a la función para obtener el historial
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
      ordenamiento = criterio; // Actualiza el texto del filtro
      // Aquí puedes implementar la lógica para ordenar los movimientos
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
            Container(
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
                    icon: Icon(
                      Icons.search,
                      color: Colors.white,
                    ), // Botón de búsqueda con ícono de lupa
                    onPressed: () {
                      setState(() {
                        searchText = _searchController.text
                            .trim(); // Obtiene el texto ingresado
                        currentPage = 1; // Reinicia a la primera página
                      });
                      fetchHistorial(); // Llama a la función para obtener el historial
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_alt,
                      color: Colors.white,
                    ), // Botón de filtro
                    onSelected: ordenarMovimientos,
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'Fecha Ascendente',
                          child: Text('Fecha Ascendente'),
                        ),
                        PopupMenuItem<String>(
                          value: 'Fecha Descendente',
                          child: Text('Fecha Descendente'),
                        ),
                        PopupMenuItem<String>(
                          value: 'RUT Ascendente',
                          child: Text('RUT Ascendente'),
                        ),
                        PopupMenuItem<String>(
                          value: 'RUT Descendente',
                          child: Text('RUT Descendente'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tipo == 'despachos'
                        ? Colors.amber
                        : Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => cambiarTipo('despachos'),
                  child: Text('Despacho'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tipo == 'recepciones'
                        ? Colors.amber
                        : Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => cambiarTipo('recepciones'),
                  child: Text('Recepción'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tipo == 'movimientos'
                        ? Colors.amber
                        : Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => cambiarTipo('movimientos'),
                  child: Text('Todos'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
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
                                'Fecha: ${mov['fecha'].toString().substring(0, 10)}',
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
                                  tipo: tipo,
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
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: paginaAnterior,
                  child: Text(
                    'Anterior',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
                Text(
                  'Página $currentPage de $totalPages',
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: siguientePagina,
                  child: Text(
                    'Siguiente',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
