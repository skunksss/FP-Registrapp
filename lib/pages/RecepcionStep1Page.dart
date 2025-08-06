import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drappnew/pages/RecepcionStep2Page.dart';
import 'package:drappnew/services/logger.dart';

// --- Función para validar el RUT chileno ---
bool validarRut(String rut) {
  if (rut.isEmpty) return false;

  // Eliminar puntos y guión, y convertir a mayúscula
  rut = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();

  // El RUT debe tener entre 8 y 9 caracteres
  if (rut.length < 8 || rut.length > 9) return false;

  final cuerpo = rut.substring(0, rut.length - 1);
  final dv = rut[rut.length - 1];

  // Verifica que el cuerpo del RUT sea numérico
  if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return false;

  // Cálculo del dígito verificador esperado
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

// --- Formateador de entrada para escribir el RUT con puntos y guión automáticamente ---
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Elimina todo lo que no sea dígito o K y convierte a mayúsculas
    String text = newValue.text
        .replaceAll(RegExp(r'[^\dkK]'), '')
        .toUpperCase();

    if (text.isEmpty) return newValue.copyWith(text: '');

    // Separa cuerpo del dígito verificador
    String cuerpo = text.length > 1 ? text.substring(0, text.length - 1) : '';
    String dv = text.substring(text.length - 1);

    // Agrega puntos cada 3 dígitos desde atrás
    String cuerpoConPuntos = '';
    int contador = 0;
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      cuerpoConPuntos = cuerpo[i] + cuerpoConPuntos;
      contador++;
      if (contador == 3 && i != 0) {
        cuerpoConPuntos = '.' + cuerpoConPuntos;
        contador = 0;
      }
    }

    String rutFormateado = cuerpoConPuntos + '-' + dv;

    // Devuelve el nuevo texto con el cursor al final
    return TextEditingValue(
      text: rutFormateado,
      selection: TextSelection.collapsed(offset: rutFormateado.length),
    );
  }
}

// --- Pantalla Paso 1: formulario para ingresar guía y RUT de empresa ---
class RecepcionStep1Page extends StatefulWidget {
  const RecepcionStep1Page({super.key});

  @override
  State<RecepcionStep1Page> createState() => _RecepcionStep1PageState();
}

class _RecepcionStep1PageState extends State<RecepcionStep1Page> {
  final guiaController = TextEditingController();
  final rutEmpresaController = TextEditingController();

  bool rutValido = false; // Estado de validación del RUT
  bool rutDirty = false; // Indica si el campo de RUT fue modificado

  // Se ejecuta cada vez que cambia el RUT
  void _onRutChanged(String value) {
    final rut = value.trim();
    setState(() {
      rutDirty = true;
      rutValido = validarRut(rut);
    });
  }

  // Función que valida y navega a la siguiente pantalla
  void _continuar() {
    final guia = guiaController.text.trim();
    final rutEmpresa = rutEmpresaController.text.trim();

    AppLogger.info(
      "Intentando continuar con guía: $guia y RUT Empresa: $rutEmpresa",
    );

    // Verifica que ambos campos estén completos
    if (guia.isEmpty || rutEmpresa.isEmpty) {
      AppLogger.warning("Campos incompletos: guía o RUT Empresa vacíos");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    // Verifica que el RUT sea válido
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

    // Navega a RecepcionStep2Page pasando los datos
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
    // Define el color del borde del campo RUT según su validez
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
                    // Campo para ingresar número de guía
                    TextField(
                      controller: guiaController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Guía',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo para ingresar RUT empresa, con formato y validación
                    TextField(
                      controller: rutEmpresaController,
                      onChanged: _onRutChanged,
                      inputFormatters: [RutInputFormatter()],
                      keyboardType: TextInputType.text,
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

                    // Muestra mensaje si el RUT es inválido
                    if (rutDirty && !rutValido)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'El RUT ingresado no es válido',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Botón para continuar
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
