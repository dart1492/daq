import 'package:daq/daq.dart';
import 'cache_storage.dart';

class CacheMutator {
  final MutationEventsController _mutationController =
      MutationEventsController.broadcast();
  final CacheStorage _cacheStorage;

  CacheMutator(this._cacheStorage);

  /// Stream of cache mutation events
  Stream<CacheMutationEvent> get mutationStream => _mutationController.stream;

  /// Single key update
  void updateCacheBySingleKey<T>(String key, T value, {List<String>? tags}) {
    _cacheStorage.addToCache(key, value, tags: tags);
    _mutationController.add(
      CacheMutationEvent(mutatedKeys: [key], mutatedData: {key: value}),
    );
  }

  /// Batch update
  /// Where key -> newData in the [mutatedData]
  void updateCacheBatch(
    List<String> mutatedKeys,
    Map<String, dynamic> mutatedData,
  ) {
    _mutationController.add(
      CacheMutationEvent(mutatedKeys: mutatedKeys, mutatedData: mutatedData),
    );
  }

  /// Dispose resources
  void dispose() {
    _mutationController.close();
  }
}
