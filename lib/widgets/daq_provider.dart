import 'package:daq/utils/daq_cache/index.dart';
import 'package:flutter/material.dart';

/// This can be used to provide a [QueryClient] throughout the application.
class DAQProvider extends InheritedWidget {
  final DAQCache daqCache;

  const DAQProvider({super.key, required this.daqCache, required super.child});

  /// Factory constructor to create provider with configuration
  factory DAQProvider.withConfig({
    Key? key,
    required DAQConfig config,
    required Widget child,
  }) {
    final cache = DAQCache(config: config);
    return DAQProvider(key: key, daqCache: cache, child: child);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;

  static DAQProvider of(BuildContext context) {
    final DAQProvider? result = context
        .dependOnInheritedWidgetOfExactType<DAQProvider>();
    assert(
      result != null,
      'DAQ provider not found! Need to wrap the app in a DAQ provider widget',
    );
    return result!;
  }
}
