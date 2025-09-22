/// Configuration class for DAQ cache
class DAQConfig {
  /// DISABLED LOGGING BY DEFAULT
  final bool enableLogging;

  DAQConfig({bool? enableLogging}) : enableLogging = enableLogging ?? false;
}
