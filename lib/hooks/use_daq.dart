import 'package:daq/utils/daq_cache/daq_cache.dart';
import 'package:daq/widgets/daq_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Get the cache object that is provided through context
DAQCache useDAQCache() {
  final context = useContext();
  return DAQProvider.of(context).daqCache;
}
