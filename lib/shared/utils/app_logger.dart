import 'package:talker_flutter/talker_flutter.dart';

class AppLogger {
  static final Talker talker = TalkerFlutter.init(
    logger: TalkerLogger(
      settings: TalkerLoggerSettings(enableColors: false),
    ),
  );

  static void debug(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.debug(message, error, stackTrace);
  }

  static void info(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.info(message, error, stackTrace);
  }

  static void warning(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.warning(message, error, stackTrace);
  }

  static void error(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.error(message, error, stackTrace);
  }

  static void fatal(
    final dynamic message, [
    final dynamic error,
    final StackTrace? stackTrace,
  ]) {
    talker.critical(message, error, stackTrace);
  }
}
