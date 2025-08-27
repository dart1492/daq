import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:daq/hooks/use_daq.dart';

/// A custom hook that provides conditional debug printing based on DAQ configuration
///
/// This hook taps into the DAQ context and returns a debug print function that
/// only executes when logging is enabled in the DAQ configuration.
///
/// Usage:
/// ```dart
/// final daqDebugPrint = useDAQDebug();
///
/// // This will only print if config.enableLogging is true
/// daqDebugPrint('[Component] Some debug message');
/// ```
void Function(String message) useDAQDebug() {
  final daqCache = useDAQCache();

  final daqDebugPrint = useCallback((String message) {
    if (daqCache.config.enableLogging) {
      debugPrint(message);
    }
  }, [daqCache.config.enableLogging]);

  return daqDebugPrint;
}
