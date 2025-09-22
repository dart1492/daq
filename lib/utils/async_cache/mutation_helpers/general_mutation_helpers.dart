import 'package:daq/utils/async_cache/index.dart';

/// Helper functions for common cache mutation patterns
/// These utilities make it easier to work with cache mutations in a consistent way
extension DAQCacheMutationHelpers on DAQCache {
  void updateEntity<T>(String cacheKey, T entity, {List<String>? tags}) {
    updateCache(cacheKey, entity, tags: tags);
  }

  // void updateEntityFields(String cacheKey, Map<String, dynamic> fields) {
  //   updateCacheFields(cacheKey, fields);
  // }

  // void addToList<T>(String listCacheKey, T item, {bool prepend = false}) {
  //   mergeCacheList(listCacheKey, [item], append: !prepend);
  // }

  // void removeFromList<T>(String listCacheKey, bool Function(T) predicate) {
  //   removeCacheListItems(listCacheKey, predicate);
  // }

  // void updateInList<T>(
  //   String listCacheKey,
  //   bool Function(T) finder,
  //   T Function(T) updater,
  // ) {
  //   updateCacheListItem(listCacheKey, finder, updater);
  // }

  // void updateByPattern(
  //   String pattern,
  //   dynamic Function(String key, dynamic oldValue) updater,
  // ) {
  //   updateCacheByPattern(pattern, updater);
  // }
}
