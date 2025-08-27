import 'package:daq/utils/async_cache/daq_cache.dart';
import 'package:daq/widgets/daq_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

DAQCache useDAQCache() {
  final context = useContext();
  return DAQProvider.of(context).daqCache;
}
