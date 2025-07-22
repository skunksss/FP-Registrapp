import 'package:flutter/material.dart';
import 'package:drappnew/pages/DespachoStep2Page.dart';
import 'package:drappnew/services/logger.dart';

class DespachoStep1Page extends StatefulWidget {
  const DespachoStep1Page({super.key});

  @override
  State<DespachoStep1Page> createState() => _DespachoStep1PageState();
}

class _DespachoStep1PageState extends State<DespachoStep1Page> {
  final guiaController = TextEditingController();
  final rutEmpresaController = TextEditingController();

  void _continuar() {
    final guia = guiaController.text.trim();
    final rutEmpresa = rutEmpresaController.text.trim();

    AppLogger.info(
      "Intentando continuar con guía: $guia y RUT Empresa: $rutEmpresa",
    );

    if (guia.isNotEmpty && rutEmpresa.isNotEmpty) {
      AppLogger.info(
        "Navegando a DespachoStep2Page con guía: $guia y RUT Empresa: $rutEmpresa",
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DespachoStep2Page(numeroGuia: guia, rutEmpresa: rutEmpresa),
        ),
      );
    } else {
      AppLogger.warning("Campos incompletos: guía o RUT Empresa vacíos");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.amber,
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Ingresar:',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: guiaController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Guía',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: rutEmpresaController,
                      decoration: const InputDecoration(
                        labelText: 'RUT Empresa',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continuar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Aceptar y continuar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
