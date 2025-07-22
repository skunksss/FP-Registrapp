// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:drappnew/pages/DespachoStep1Page.dart';
import 'package:drappnew/pages/RecepcionStep1Page.dart';
import 'package:drappnew/pages/HistorialPage.dart';
import 'package:drappnew/services/logger.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RegistrApp',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber),
              child: Center(
                child: Text(
                  'Menú',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Despachos'),
              onTap: () {
                AppLogger.info("Navegando a Despachos");
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DespachoStep1Page(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Recepciones'),
              onTap: () {
                AppLogger.info("Navegando a Recepciones");
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecepcionStep1Page(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Historial'),
              onTap: () {
                AppLogger.info("Navegando a Historial");
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistorialPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                AppLogger.info("Cerrando sesión");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/images/fpetricio-logo-small-blanco.png'),
                  const SizedBox(height: 20),
                  const Text(
                    'Gestión de cargas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      AppLogger.info("Navegando a Despacho desde Home");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DespachoStep1Page(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 70),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Despacho'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      AppLogger.info("Navegando a Recepción desde Home");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecepcionStep1Page(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 70),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Recepción'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Esta aplicación está diseñada\n'
                    'para facilitar la gestión de despachos \n'
                    'y recepciones en la empresa.\n\n'
                    'Aquí podrás consultar y gestionar \n'
                    'las operaciones diarias de manera eficiente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/body1.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ver historial',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      AppLogger.info("Navegando a Historial desde Home");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistorialPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 70),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Historial'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Consulta el historial completo de todas tus operaciones\n'
                    'y mantén un registro detallado de cada movimiento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/body2.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
