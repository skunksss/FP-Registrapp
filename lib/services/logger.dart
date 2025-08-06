// lib/services/logger.dart

import 'package:logger/logger.dart';

/// Clase estática para centralizar el registro de logs de la app.
/// Utiliza el paquete "logger" para mostrar logs en consola con formato bonito.
class AppLogger {
  // Instancia interna del logger, configurada con PrettyPrinter.
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Cuántos métodos del stack mostrar.
      errorMethodCount: 5, // Cuántos métodos mostrar en caso de error.
      colors: true, // Colores en consola.
      printEmojis: false, // Emojis (opcional).
      printTime: true, // Mostrar hora del log.
    ),
  );

  /// Log de tipo DEBUG (para desarrollo).
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error, stackTrace);
  }

  /// Log de tipo INFO (información general).
  static void info(String message) {
    _logger.i(message);
  }

  /// Log de tipo WARNING (algo no crítico, pero a observar).
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error, stackTrace);
  }

  /// Log de tipo ERROR (algo falló).
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
  }

  /// Log de tipo FATAL (algo muy grave, tipo crash).
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error, stackTrace); // "What a Terrible Failure"
  }
}
