import 'package:daq/hooks/use_paginated_query.dart';
import 'package:daq/utils/async_cache/index.dart';

/// Helper functions for common cache mutation patterns
/// These utilities make it easier to work with cache mutations in a consistent way

extension DAQCacheMutationHelpers on DAQCache {
  void updateEntity<T>(String cacheKey, T entity, {List<String>? tags}) {
    updateCache(cacheKey, entity, tags: tags);
  }

  void updateEntityFields(String cacheKey, Map<String, dynamic> fields) {
    updateCacheFields(cacheKey, fields);
  }

  void addToList<T>(String listCacheKey, T item, {bool prepend = false}) {
    mergeCacheList(listCacheKey, [item], append: !prepend);
  }

  void removeFromList<T>(String listCacheKey, bool Function(T) predicate) {
    removeCacheListItems(listCacheKey, predicate);
  }

  void updateInList<T>(
    String listCacheKey,
    bool Function(T) finder,
    T Function(T) updater,
  ) {
    updateCacheListItem(listCacheKey, finder, updater);
  }

  void updateByPattern(
    String pattern,
    dynamic Function(String key, dynamic oldValue) updater,
  ) {
    updateCacheByPattern(pattern, updater);
  }

  void addToPaginatedFirstPage<T>(String cachePrefix, int filterHash, T item) {
    final firstPageKey = '${cachePrefix}_${filterHash}_page_1';
    final cachedFirstPage = getValue<DAQPaginatedResponse<T>>(firstPageKey);

    if (cachedFirstPage != null) {
      final updatedItems = [item, ...cachedFirstPage.items];
      final updatedPage = DAQPaginatedResponse<T>(
        items: updatedItems,
        totalItems: cachedFirstPage.totalItems + 1,
        totalPages: cachedFirstPage.totalPages,
        hasNextPage: cachedFirstPage.hasNextPage,
        currentPage: 1,
      );
      updateCache(firstPageKey, updatedPage);
    }
  }

  void updateCachePaginatedItem<T>(
    String key,
    bool Function(T item) finder,
    T Function(T item) updater,
  ) {
    final cachedData = this.getValue(key);

    if (cachedData is DAQPaginatedResponse<T>) {
      final updatedItems = cachedData.items.map((item) {
        if (finder(item)) {
          return updater(item);
        }
        return item;
      }).toList();

      // Create updated paginated response with new items
      final updatedResponse = DAQPaginatedResponse<T>(
        items: updatedItems,
        totalItems: cachedData.totalItems,
        totalPages: cachedData.totalPages,
        hasNextPage: cachedData.hasNextPage,
        currentPage: cachedData.currentPage,
      );

      updateCache(key, updatedResponse);
    }
  }

  void updateItemInAllPaginatedResponses<T>(
    String cachePrefix,
    bool Function(T item) matcher,
    T Function(T item) updater,
  ) {
    // final mutatedKeys = <String>[];
    // final mutatedData = <String, dynamic>{};

    // Find all cache keys that start with the prefix
    final relevantKeys = keys
        .where((key) => key.startsWith(cachePrefix))
        .toList();

    for (final key in relevantKeys) {
      final cachedData = getValue(key);

      // Check if this is a paginated response
      if (cachedData is DAQPaginatedResponse<T>) {
        bool wasUpdated = false;
        final updatedItems = <T>[];

        // Go through each item and update if it matches
        for (final item in cachedData.items) {
          if (matcher(item)) {
            updatedItems.add(updater(item));
            wasUpdated = true;
          } else {
            updatedItems.add(item);
          }
        }

        // Only update cache if something actually changed
        if (wasUpdated) {
          final updatedResponse = DAQPaginatedResponse<T>(
            items: updatedItems,
            totalItems: cachedData.totalItems,
            totalPages: cachedData.totalPages,
            hasNextPage: cachedData.hasNextPage,
            currentPage: cachedData.currentPage,
          );

          this.updateCache(key, updatedResponse);

          // mutatedKeys.add(key);
          // mutatedData[key] = updatedResponse;
        }
      }
    }

    // // Notify listeners if any mutations occurred
    // if (mutatedKeys.isNotEmpty) {
    //   _mutationController.add(
    //     CacheMutationEvent(
    //       mutatedKeys: mutatedKeys,
    //       mutatedData: mutatedData,
    //       pattern: '${cachePrefix}*',
    //     ),
    //   );
    //   print(
    //     '🔄 Updated item in ${mutatedKeys.length} paginated responses with prefix: $cachePrefix',
    //   );
    // }
  }
}
