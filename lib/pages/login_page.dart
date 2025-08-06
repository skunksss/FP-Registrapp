import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drappnew/services/auth_service.dart';
import 'package:drappnew/pages/home_page.dart';
import 'package:drappnew/services/logger.dart';

/// --- Función de validación de RUT chileno ---
/// Verifica si el RUT tiene el formato correcto y el dígito verificador válido.
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

/// --- Formateador de entrada para RUT chileno ---
/// Da formato en tiempo real al texto ingresado (ej: 12.345.678-K).
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text
        .replaceAll(
          RegExp(r'[^\dkK]'),
          '',
        ) // Elimina todo lo que no sea número o K
        .toUpperCase();

    if (text.isEmpty) return newValue.copyWith(text: '');

    String cuerpo = text.length > 1 ? text.substring(0, text.length - 1) : '';
    String dv = text.substring(text.length - 1);

    // Agrega puntos cada tres cifras desde la derecha
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

    return TextEditingValue(
      text: rutFormateado,
      selection: TextSelection.collapsed(offset: rutFormateado.length),
    );
  }
}

/// Página de inicio de sesión con validación de RUT y autenticación.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final rutController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  bool rutValido = false;
  bool rutDirty = false; // Marca si el usuario ya escribió algo en el campo RUT

  /// Lógica para validar el RUT en tiempo real
  void _onRutChanged(String value) {
    final rut = value.trim();
    setState(() {
      rutDirty = true;
      rutValido = validarRut(rut);
    });
  }

  /// Función que maneja el inicio de sesión
  void _login() async {
    final rut = rutController.text.trim();
    final password = passwordController.text;

    // Validación básica de campos
    if (!rutValido || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifica RUT o contraseña')),
      );
      return;
    }

    setState(() => isLoading = true);
    AppLogger.info("Intentando iniciar sesión con RUT: $rut");

    try {
      final success = await AuthService.login(rut, password);
      setState(() => isLoading = false);

      if (success) {
        AppLogger.info("Inicio de sesión exitoso para RUT: $rut");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        AppLogger.warning("Credenciales incorrectas para RUT: $rut");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    } catch (e) {
      AppLogger.error("Error durante el inicio de sesión: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error en el inicio de sesión')),
      );
    }
  }

  /// Construcción del UI del login
  @override
  Widget build(BuildContext context) {
    // Define color del borde según validez del RUT
    final rutColor = !rutDirty
        ? Colors.grey
        : rutValido
        ? Colors.green
        : Colors.red;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'RegistrApp',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestión de despachos',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Campo de texto para el RUT con validación visual
                    TextField(
                      controller: rutController,
                      onChanged: _onRutChanged,
                      inputFormatters: [RutInputFormatter()],
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'RUT',
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
                    const SizedBox(height: 20),
                    // Campo de texto para la contraseña
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Botón de login o spinner si está cargando
                    isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: rutValido
                                    ? Colors.amber
                                    : Colors.amber.withOpacity(0.5),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(fontSize: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Iniciar sesión'),
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
