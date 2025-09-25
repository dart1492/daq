import 'package:easy_logger/easy_logger.dart';

/// A singleton logger for DAQ package that wraps around easy_logger
///
/// This logger provides structured logging with different levels and
/// respects the DAQ configuration for enabling/disabling logging.
class DAQLogger {
  static DAQLogger? _instance;
  static DAQLogger get instance => _instance ??= DAQLogger._internal();

  late EasyLogger _logger;
  bool _isEnabled = false;

  DAQLogger._internal() {
    _logger = EasyLogger(name: 'DAQ');
  }

  /// Enable or disable logging
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if logging is currently enabled
  bool get isEnabled => _isEnabled;

  /// Sanitize message by replacing newline characters with spaces
  String _sanitizeMessage(String message) {
    return message.replaceAll(RegExp(r'[\r\n]+'), ' ');
  }

  /// Log a debug message
  void debug(String message, [String? tag]) {
    if (!_isEnabled) return;

    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] $sanitizedMessage'
        : sanitizedMessage;
    _logger.debug(formattedMessage);
  }

  /// Log an info message
  void info(String message, [String? tag]) {
    if (!_isEnabled) return;
    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] $sanitizedMessage'
        : sanitizedMessage;
    _logger.info(formattedMessage);
  }

  /// Log a warning message
  void warning(String message, [String? tag]) {
    if (!_isEnabled) return;
    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] $sanitizedMessage'
        : sanitizedMessage;
    _logger.warning(formattedMessage);
  }

  /// Log an error message
  void error(
    String message, [
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_isEnabled) return;
    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] $sanitizedMessage'
        : sanitizedMessage;
    _logger.error(formattedMessage, stackTrace: stackTrace);
  }

  /// Log a success message
  void success(String message, [String? tag]) {
    if (!_isEnabled) return;
    final sanitizedMessage = _sanitizeMessage(message);
    final formattedMessage = tag != null
        ? '[$tag] $sanitizedMessage'
        : sanitizedMessage;
    _logger.debug('✅ $formattedMessage');
  }

  /// Log a query-related message
  void query(String message) {
    debug(_sanitizeMessage(message), 'DAQ Query');
  }

  /// Log a mutation-related message
  void mutation(String message) {
    debug(_sanitizeMessage(message), 'DAQ Mutation');
  }

  /// Log a cache-related message
  void cache(String message) {
    debug(_sanitizeMessage(message), 'DAQ Cache');
  }

  /// Log a paginated query-related message
  void paginatedQuery(String message) {
    debug(_sanitizeMessage(message), 'DAQ Paginated Query');
  }

  void infiniteQuery(String message) {
    debug(_sanitizeMessage(message), 'DAQ Infinite Query');
  }

  /// Log a general DAQ message
  void daq(String message) {
    debug(_sanitizeMessage(message), 'DAQ');
  }
}
