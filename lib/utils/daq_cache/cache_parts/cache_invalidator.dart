import 'package:daq/utils/daq_cache/events.dart';

import 'cache_storage.dart';

class CacheInvalidator {
  final InvalidationEventsController _invalidationController =
      InvalidationEventsController.broadcast();

  final CacheStorage _cacheStorage;

  CacheInvalidator(this._cacheStorage);

  /// Stream of cache invalidation events
  Stream<CacheInvalidationEvent> get invalidationStream =>
      _invalidationController.stream;

  /// Invalidate cache by pattern (e.g., "user_*", "bookings_*")
  void invalidateByPattern(String pattern) {
    final keysToInvalidate = _cacheStorage.getKeysByPattern(pattern);

    // Remove invalidated keys
    for (final key in keysToInvalidate) {
      _cacheStorage.removeKey(key);
    }

    // Notify listeners
    if (keysToInvalidate.isNotEmpty) {
      _invalidationController.add(
        CacheInvalidationEvent(
          invalidatedKeys: keysToInvalidate,
          pattern: pattern,
        ),
      );
    }
  }

  /// Invalidate cache by tags (e.g., ["user", "profile"])
  void invalidateByTags(List<String> tags) {
    final keysToInvalidate = _cacheStorage.getKeysByTags(tags);

    for (final key in keysToInvalidate) {
      _cacheStorage.removeKey(key);
    }

    if (keysToInvalidate.isNotEmpty) {
      _invalidationController.add(
        CacheInvalidationEvent(invalidatedKeys: keysToInvalidate, tags: tags),
      );
    }
  }

  /// Invalidate specific cache keys
  /// The full key has to be provided to invalidate the instance. So if the user, for example, has been provided with the parameter of id - we need to provide the user_{id.hasCode} to invalidate it.
  void invalidateKeys(List<String> keys) {
    final validKeysToInvalidate = keys
        .where((key) => _cacheStorage.hasKey(key))
        .toList();

    for (final key in validKeysToInvalidate) {
      _cacheStorage.removeKey(key);
    }

    // Notify listeners
    if (validKeysToInvalidate.isNotEmpty) {
      _invalidationController.add(
        CacheInvalidationEvent(invalidatedKeys: validKeysToInvalidate),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _invalidationController.close();
  }
}
