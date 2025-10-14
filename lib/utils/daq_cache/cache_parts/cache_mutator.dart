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
  void updateCacheBySingleKey<T>(
    String key,
    T value, {
    List<String>? tags,
    bool emitEvent = true,
  }) {
    _cacheStorage.addToCache<T>(key, value, tags: tags);

    if (emitEvent) {
      _mutationController.add(
        CacheMutationEvent(mutatedKeys: [key], mutatedData: {key: value}),
      );
    }
  }

  /// Batch update
  /// Where key -> newData in the [mutatedData]
  void updateCacheBatch(
    List<String> mutatedKeys,
    Map<String, dynamic> mutatedData, {

    /// To make the rebuild where the query is instantiated
    bool emitEvent = true,
  }) {
    mutatedData.forEach((key, value) {
      _cacheStorage.addToCache(key, value);
    });

    if (emitEvent) {
      _mutationController.add(
        CacheMutationEvent(mutatedKeys: mutatedKeys, mutatedData: mutatedData),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _mutationController.close();
  }
}
