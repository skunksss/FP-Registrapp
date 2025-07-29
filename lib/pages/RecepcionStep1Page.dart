import 'package:flutter/material.dart';
import 'package:drappnew/pages/RecepcionStep2Page.dart';
import 'package:drappnew/services/logger.dart';

// --- Función de validación de RUT chileno ---
bool validarRut(String rut) {
  if (rut.isEmpty) return false;
  rut = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();

  if (rut.length < 8 || rut.length > 9) return false;

  final cuerpo = rut.substring(0, rut.length - 1);
  final dv = rut[rut.length - 1];

  if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return false;

  int suma = 0;
  int multiplo = 2;

  for (int i = cuerpo.length - 1; i >= 0; i--) {
    suma += int.parse(cuerpo[i]) * multiplo;
    multiplo = multiplo == 7 ? 2 : multiplo + 1;
  }

  int digitoEsperado = 11 - (suma % 11);
  String dvEsperado;
  if (digitoEsperado == 11) {
    dvEsperado = '0';
  } else if (digitoEsperado == 10) {
    dvEsperado = 'K';
  } else {
    dvEsperado = digitoEsperado.toString();
  }

  return dv == dvEsperado;
}

class RecepcionStep1Page extends StatefulWidget {
  const RecepcionStep1Page({super.key});

  @override
  State<RecepcionStep1Page> createState() => _RecepcionStep1PageState();
}

class _RecepcionStep1PageState extends State<RecepcionStep1Page> {
  final guiaController = TextEditingController();
  final rutEmpresaController = TextEditingController();
  bool rutValido = false;
  bool rutDirty = false;

  void _onRutChanged(String value) {
    final rut = value.trim();
    setState(() {
      rutDirty = true;
      rutValido = validarRut(rut);
    });
  }

  void _continuar() {
    final guia = guiaController.text.trim();
    final rutEmpresa = rutEmpresaController.text.trim();

    AppLogger.info(
      "Intentando continuar con guía: $guia y RUT Empresa: $rutEmpresa",
    );

    if (guia.isEmpty || rutEmpresa.isEmpty) {
      AppLogger.warning("Campos incompletos: guía o RUT Empresa vacíos");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (!rutValido) {
      AppLogger.warning("RUT Empresa inválido");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El RUT ingresado no es válido')),
      );
      return;
    }

    AppLogger.info(
      "Navegando a RecepcionStep2Page con guía: $guia y RUT Empresa: $rutEmpresa",
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecepcionStep2Page(numeroGuia: guia, rutEmpresa: rutEmpresa),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rutColor = !rutDirty
        ? Colors.grey
        : rutValido
        ? Colors.green
        : Colors.red;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.amber,
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
                      onChanged: _onRutChanged,
                      decoration: InputDecoration(
                        labelText: 'RUT Empresa',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: rutColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: rutColor, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: rutColor, width: 2),
                        ),
                        suffixIcon: !rutDirty
                            ? null
                            : rutValido
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.close, color: Colors.red),
                      ),
                    ),
                    if (rutDirty && !rutValido)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'El RUT ingresado no es válido',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continuar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rutValido
                              ? Colors.amber
                              : Colors.amber.withOpacity(0.5),
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
