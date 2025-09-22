import 'package:daq/utils/daq_cache/events.dart';
import 'cache_storage.dart';

class CacheMutator {
  final MutationEventsController _mutationController =
      MutationEventsController.broadcast();
  final CacheStorage _cacheStorage;

  CacheMutator(this._cacheStorage);

  /// Stream of cache mutation events
  Stream<CacheMutationEvent> get mutationStream => _mutationController.stream;

  /// Update cache with new data and notify listeners
  void updateCache<T>(String key, T value, {List<String>? tags}) {
    _cacheStorage.addToCache(key, value, tags: tags);

    // Notify listeners about the mutation
    _mutationController.add(
      CacheMutationEvent(mutatedKeys: [key], mutatedData: {key: value}),
    );
  }

  // TODO: RETHING CACHE MUTATIONS TO A MORE STRUCTURED FORMAT

  // /// Update multiple cache entries at once
  // void updateCacheMultiple(
  //   Map<String, dynamic> updates, {
  //   Map<String, List<String>>? keyTags,
  // }) {
  //   final mutatedKeys = <String>[];
  //   final mutatedData = <String, dynamic>{};

  //   for (final entry in updates.entries) {
  //     final key = entry.key;
  //     final value = entry.value;

  //     _cacheStorage.addToCache(key, value, tags: keyTags?[key]);
  //     mutatedKeys.add(key);
  //     mutatedData[key] = value;
  //   }

  //   if (mutatedKeys.isNotEmpty) {
  //     _mutationController.add(
  //       CacheMutationEvent(mutatedKeys: mutatedKeys, mutatedData: mutatedData),
  //     );
  //   }
  // }

  // /// Update cache by pattern (useful for bulk updates)
  // void updateCacheByPattern<T>(
  //   String pattern,
  //   T Function(String key, dynamic oldValue) updater, {
  //   List<String>? tags,
  // }) {
  //   final regex = RegExp(pattern.replaceAll('*', '.*'));
  //   final mutatedKeys = <String>[];
  //   final mutatedData = <String, dynamic>{};

  //   for (final entry in _cacheStorage.cacheInstance.entries) {
  //     if (regex.hasMatch(entry.key)) {
  //       final newValue = updater(entry.key, entry.value);
  //       _cacheStorage.addToCache(entry.key, newValue, tags: tags);
  //       mutatedKeys.add(entry.key);
  //       mutatedData[entry.key] = newValue;
  //     }
  //   }

  //   if (mutatedKeys.isNotEmpty) {
  //     _mutationController.add(
  //       CacheMutationEvent(
  //         mutatedKeys: mutatedKeys,
  //         mutatedData: mutatedData,
  //         pattern: pattern,
  //         tags: tags,
  //       ),
  //     );
  //   }
  // }

  // /// Update cache by tags
  // void updateCacheByTags<T>(
  //   List<String> tags,
  //   T Function(String key, dynamic oldValue) updater,
  // ) {
  //   final tagsSet = tags.toSet();
  //   final mutatedKeys = <String>[];
  //   final mutatedData = <String, dynamic>{};

  //   for (final entry in _cacheStorage.keyTags.entries) {
  //     if (entry.value.any((tag) => tagsSet.contains(tag))) {
  //       final key = entry.key;
  //       final oldValue = _cacheStorage.getValue(key);
  //       if (oldValue != null) {
  //         final newValue = updater(key, oldValue);
  //         _cacheStorage.addToCache(key, newValue);
  //         mutatedKeys.add(key);
  //         mutatedData[key] = newValue;
  //       }
  //     }
  //   }

  //   if (mutatedKeys.isNotEmpty) {
  //     _mutationController.add(
  //       CacheMutationEvent(
  //         mutatedKeys: mutatedKeys,
  //         mutatedData: mutatedData,
  //         tags: tags,
  //       ),
  //     );
  //   }
  // }

  // // =================== HELPER METHODS FOR COMMON PATTERNS ===================

  // /// Create or update a cache entry (commonly used for entity updates)
  // void upsertCache<T>(String key, T value, {List<String>? tags}) {
  //   updateCache(key, value, tags: tags);
  // }

  // /// Update a specific field in a cached object (if it's a Map/JSON-like structure)
  // void updateCacheField(String key, String field, dynamic value) {
  //   final cachedData = _cacheStorage.getValue(key);
  //   if (cachedData is Map<String, dynamic>) {
  //     final updatedData = Map<String, dynamic>.from(cachedData);
  //     updatedData[field] = value;
  //     updateCache(key, updatedData);
  //   }
  // }

  // /// Update multiple fields in a cached object
  // void updateCacheFields(String key, Map<String, dynamic> fieldUpdates) {
  //   final cachedData = _cacheStorage.getValue(key);
  //   if (cachedData is Map<String, dynamic>) {
  //     final updatedData = Map<String, dynamic>.from(cachedData);
  //     updatedData.addAll(fieldUpdates);
  //     updateCache(key, updatedData);
  //   }
  // }

  // /// Merge new data into existing cached list (useful for pagination or adding items)
  // void mergeCacheList<T>(String key, List<T> newItems, {bool append = true}) {
  //   final cachedData = _cacheStorage.getValue(key);
  //   if (cachedData is List<T>) {
  //     final updatedList = List<T>.from(cachedData);
  //     if (append) {
  //       updatedList.addAll(newItems);
  //     } else {
  //       updatedList.insertAll(0, newItems);
  //     }
  //     updateCache(key, updatedList);
  //   } else {
  //     // If no existing list, just set the new items
  //     updateCache(key, newItems);
  //   }
  // }

  // /// Remove items from a cached list
  // void removeCacheListItems<T>(String key, bool Function(T item) predicate) {
  //   final cachedData = _cacheStorage.getValue(key);
  //   if (cachedData is List<T>) {
  //     final updatedList = cachedData.where((item) => !predicate(item)).toList();
  //     updateCache(key, updatedList);
  //   }
  // }

  // /// Update an item in a cached list
  // void updateCacheListItem<T>(
  //   String key,
  //   bool Function(T item) finder,
  //   T Function(T item) updater,
  // ) {
  //   final cachedData = _cacheStorage.getValue(key);

  //   if (cachedData is List<T>) {
  //     final updatedList = cachedData.map((item) {
  //       if (finder(item)) {
  //         return updater(item);
  //       }
  //       return item;
  //     }).toList();
  //     updateCache(key, updatedList);
  //   }
  // }

  // /// Update an item in a paginated response
  // void updateCachePaginatedItem<T>(
  //   String key,
  //   bool Function(T item) finder,
  //   T Function(T item) updater,
  // ) {
  //   final cachedData = _cacheStorage.getValue(key);

  //   if (cachedData is DAQPaginatedQueryResponse<T>) {
  //     final updatedItems = cachedData.items.map((item) {
  //       if (finder(item)) {
  //         return updater(item);
  //       }
  //       return item;
  //     }).toList();

  //     // Create updated paginated response with new items
  //     final updatedResponse = DAQPaginatedQueryResponse<T>(
  //       items: updatedItems,
  //       totalItems: cachedData.totalItems,
  //       totalPages: cachedData.totalPages,
  //       hasNextPage: cachedData.hasNextPage,
  //       currentPage: cachedData.currentPage,
  //     );

  //     updateCache(key, updatedResponse);
  //   }
  // }

  // /// Update an item across all paginated responses with a given prefix
  // /// This searches through ALL cached paginated responses that start with the prefix
  // /// and updates any items that match the matcher function
  // void updateItemInAllPaginatedResponses<T>(
  //   String cachePrefix,
  //   bool Function(T item) matcher,
  //   T Function(T item) updater,
  // ) {
  //   final mutatedKeys = <String>[];
  //   final mutatedData = <String, dynamic>{};

  //   // Find all cache keys that start with the prefix
  //   final relevantKeys = _cacheStorage.cacheInstance.keys
  //       .where((key) => key.startsWith(cachePrefix))
  //       .toList();

  //   for (final key in relevantKeys) {
  //     final cachedData = _cacheStorage.getValue(key);

  //     // Check if this is a paginated response
  //     if (cachedData is DAQPaginatedQueryResponse<T>) {
  //       bool wasUpdated = false;
  //       final updatedItems = <T>[];

  //       // Go through each item and update if it matches
  //       for (final item in cachedData.items) {
  //         if (matcher(item)) {
  //           updatedItems.add(updater(item));
  //           wasUpdated = true;
  //         } else {
  //           updatedItems.add(item);
  //         }
  //       }

  //       // Only update cache if something actually changed
  //       if (wasUpdated) {
  //         final updatedResponse = DAQPaginatedQueryResponse<T>(
  //           items: updatedItems,
  //           totalItems: cachedData.totalItems,
  //           totalPages: cachedData.totalPages,
  //           hasNextPage: cachedData.hasNextPage,
  //           currentPage: cachedData.currentPage,
  //         );

  //         _cacheStorage.addToCache(key, updatedResponse);
  //         mutatedKeys.add(key);
  //         mutatedData[key] = updatedResponse;
  //       }
  //     }
  //   }

  //   // Notify listeners if any mutations occurred
  //   if (mutatedKeys.isNotEmpty) {
  //     _mutationController.add(
  //       CacheMutationEvent(
  //         mutatedKeys: mutatedKeys,
  //         mutatedData: mutatedData,
  //         pattern: '$cachePrefix*',
  //       ),
  //     );

  //     DAQLogger.instance.cache(
  //       '🔄 Updated item in ${mutatedKeys.length} paginated responses with prefix: $cachePrefix',
  //     );
  //   }
  // }

  /// Dispose resources
  void dispose() {
    _mutationController.close();
  }
}
