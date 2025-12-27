import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 10,
      errorMethodCount: 10,
      colors: false,
      printEmojis: false,
    ),
  );

  static void debug(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
