import 'dart:async';

import 'package:daq/hooks/use_paginated_query.dart';
import 'package:daq/utils/async_cache/daq_config.dart';
import 'package:daq/utils/async_cache/events.dart';
import 'package:flutter/material.dart';

class DAQCache {
  DAQCache({required this.config});

  final DAQConfig config;

  final Map<String, dynamic> _cacheInstance = {};
  final Map<String, Set<String>> _keyTags = {}; // key -> tags

  final StreamController<CacheInvalidationEvent> _invalidationController =
      StreamController<CacheInvalidationEvent>.broadcast();
  final StreamController<CacheMutationEvent> _mutationController =
      StreamController<CacheMutationEvent>.broadcast();

  /// Stream of cache invalidation events
  Stream<CacheInvalidationEvent> get invalidationStream =>
      _invalidationController.stream;

  /// Stream of cache mutation events
  Stream<CacheMutationEvent> get mutationStream => _mutationController.stream;

  void addToCache<T>(String key, T value, {List<String>? tags}) {
    _cacheInstance[key] = value;

    // Store tags for this key if provided
    if (tags != null && tags.isNotEmpty) {
      _keyTags[key] = tags.toSet();
    }
  }

  T? getValue<T>(String key) {
    final value = _cacheInstance[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  bool hasKey(String key) {
    return _cacheInstance.containsKey(key);
  }

  void removeKey(String key) {
    _cacheInstance.remove(key);
    _keyTags.remove(key);
  }

  void clearAll() {
    _cacheInstance.clear();
    _keyTags.clear();
  }

  List<String> get keys => _cacheInstance.keys.toList();

  /// Invalidate cache by pattern (e.g., "user_*", "bookings_*")
  void invalidateByPattern(String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    final keysToInvalidate = _cacheInstance.keys
        .where((key) => regex.hasMatch(key))
        .toList();

    // Remove invalidated keys
    for (final key in keysToInvalidate) {
      removeKey(key);
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
    final tagsSet = tags.toSet();
    final keysToInvalidate = <String>[];

    for (final entry in _keyTags.entries) {
      if (entry.value.any((tag) => tagsSet.contains(tag))) {
        keysToInvalidate.add(entry.key);
      }
    }

    for (final key in keysToInvalidate) {
      removeKey(key);
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
    final validKeysToInvalidate = keys.where((key) => hasKey(key)).toList();

    for (final key in validKeysToInvalidate) {
      removeKey(key);
    }

    // Notify listeners
    if (validKeysToInvalidate.isNotEmpty) {
      _invalidationController.add(
        CacheInvalidationEvent(invalidatedKeys: validKeysToInvalidate),
      );
    }
  }

  /// Get tags for a specific key
  Set<String>? getTagsForKey(String key) {
    return _keyTags[key];
  }

  /// Get all keys that have a specific tag
  List<String> getKeysByTag(String tag) {
    return _keyTags.entries
        .where((entry) => entry.value.contains(tag))
        .map((entry) => entry.key)
        .toList();
  }

  // =================== CACHE MUTATION METHODS ===================

  /// Update cache with new data and notify listeners
  void updateCache<T>(String key, T value, {List<String>? tags}) {
    _cacheInstance[key] = value;

    // Update tags if provided
    if (tags != null && tags.isNotEmpty) {
      _keyTags[key] = tags.toSet();
    }

    // Notify listeners about the mutation
    _mutationController.add(
      CacheMutationEvent(mutatedKeys: [key], mutatedData: {key: value}),
    );
  }

  /// Update multiple cache entries at once
  void updateCacheMultiple(
    Map<String, dynamic> updates, {
    Map<String, List<String>>? keyTags,
  }) {
    final mutatedKeys = <String>[];
    final mutatedData = <String, dynamic>{};

    for (final entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;

      _cacheInstance[key] = value;
      mutatedKeys.add(key);
      mutatedData[key] = value;

      // Update tags if provided for this key
      if (keyTags != null && keyTags.containsKey(key)) {
        _keyTags[key] = keyTags[key]!.toSet();
      }
    }

    if (mutatedKeys.isNotEmpty) {
      _mutationController.add(
        CacheMutationEvent(mutatedKeys: mutatedKeys, mutatedData: mutatedData),
      );
    }
  }

  /// Update cache by pattern (useful for bulk updates)
  void updateCacheByPattern<T>(
    String pattern,
    T Function(String key, dynamic oldValue) updater, {
    List<String>? tags,
  }) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    final mutatedKeys = <String>[];
    final mutatedData = <String, dynamic>{};

    for (final entry in _cacheInstance.entries) {
      if (regex.hasMatch(entry.key)) {
        final newValue = updater(entry.key, entry.value);
        _cacheInstance[entry.key] = newValue;
        mutatedKeys.add(entry.key);
        mutatedData[entry.key] = newValue;

        // Update tags if provided
        if (tags != null && tags.isNotEmpty) {
          _keyTags[entry.key] = tags.toSet();
        }
      }
    }

    if (mutatedKeys.isNotEmpty) {
      _mutationController.add(
        CacheMutationEvent(
          mutatedKeys: mutatedKeys,
          mutatedData: mutatedData,
          pattern: pattern,
          tags: tags,
        ),
      );
    }
  }

  /// Update cache by tags
  void updateCacheByTags<T>(
    List<String> tags,
    T Function(String key, dynamic oldValue) updater,
  ) {
    final tagsSet = tags.toSet();
    final mutatedKeys = <String>[];
    final mutatedData = <String, dynamic>{};

    for (final entry in _keyTags.entries) {
      if (entry.value.any((tag) => tagsSet.contains(tag))) {
        final key = entry.key;
        final oldValue = _cacheInstance[key];
        if (oldValue != null) {
          final newValue = updater(key, oldValue);
          _cacheInstance[key] = newValue;
          mutatedKeys.add(key);
          mutatedData[key] = newValue;
        }
      }
    }

    if (mutatedKeys.isNotEmpty) {
      _mutationController.add(
        CacheMutationEvent(
          mutatedKeys: mutatedKeys,
          mutatedData: mutatedData,
          tags: tags,
        ),
      );
    }
  }

  // =================== HELPER METHODS FOR COMMON PATTERNS ===================

  /// Create or update a cache entry (commonly used for entity updates)
  void upsertCache<T>(String key, T value, {List<String>? tags}) {
    updateCache(key, value, tags: tags);
  }

  /// Update a specific field in a cached object (if it's a Map/JSON-like structure)
  void updateCacheField(String key, String field, dynamic value) {
    final cachedData = _cacheInstance[key];
    if (cachedData is Map<String, dynamic>) {
      final updatedData = Map<String, dynamic>.from(cachedData);
      updatedData[field] = value;
      updateCache(key, updatedData);
    }
  }

  /// Update multiple fields in a cached object
  void updateCacheFields(String key, Map<String, dynamic> fieldUpdates) {
    final cachedData = _cacheInstance[key];
    if (cachedData is Map<String, dynamic>) {
      final updatedData = Map<String, dynamic>.from(cachedData);
      updatedData.addAll(fieldUpdates);
      updateCache(key, updatedData);
    }
  }

  /// Merge new data into existing cached list (useful for pagination or adding items)
  void mergeCacheList<T>(String key, List<T> newItems, {bool append = true}) {
    final cachedData = _cacheInstance[key];
    if (cachedData is List<T>) {
      final updatedList = List<T>.from(cachedData);
      if (append) {
        updatedList.addAll(newItems);
      } else {
        updatedList.insertAll(0, newItems);
      }
      updateCache(key, updatedList);
    } else {
      // If no existing list, just set the new items
      updateCache(key, newItems);
    }
  }

  /// Remove items from a cached list
  void removeCacheListItems<T>(String key, bool Function(T item) predicate) {
    final cachedData = _cacheInstance[key];
    if (cachedData is List<T>) {
      final updatedList = cachedData.where((item) => !predicate(item)).toList();
      updateCache(key, updatedList);
    }
  }

  /// Update an item in a cached list
  void updateCacheListItem<T>(
    String key,
    bool Function(T item) finder,
    T Function(T item) updater,
  ) {
    final cachedData = _cacheInstance[key];

    if (cachedData is List<T>) {
      final updatedList = cachedData.map((item) {
        if (finder(item)) {
          return updater(item);
        }
        return item;
      }).toList();
      updateCache(key, updatedList);
    }
  }

  /// Update an item in a paginated response
  void updateCachePaginatedItem<T>(
    String key,
    bool Function(T item) finder,
    T Function(T item) updater,
  ) {
    final cachedData = _cacheInstance[key];

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

  /// Update an item across all paginated responses with a given prefix
  /// This searches through ALL cached paginated responses that start with the prefix
  /// and updates any items that match the matcher function
  void updateItemInAllPaginatedResponses<T>(
    String cachePrefix,
    bool Function(T item) matcher,
    T Function(T item) updater,
  ) {
    final mutatedKeys = <String>[];
    final mutatedData = <String, dynamic>{};

    // Find all cache keys that start with the prefix
    final relevantKeys = _cacheInstance.keys
        .where((key) => key.startsWith(cachePrefix))
        .toList();

    for (final key in relevantKeys) {
      final cachedData = _cacheInstance[key];

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

          _cacheInstance[key] = updatedResponse;
          mutatedKeys.add(key);
          mutatedData[key] = updatedResponse;
        }
      }
    }

    // Notify listeners if any mutations occurred
    if (mutatedKeys.isNotEmpty) {
      _mutationController.add(
        CacheMutationEvent(
          mutatedKeys: mutatedKeys,
          mutatedData: mutatedData,
          pattern: '$cachePrefix*',
        ),
      );

      debugPrint(
        '🔄 Updated item in ${mutatedKeys.length} paginated responses with prefix: $cachePrefix',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _invalidationController.close();
    _mutationController.close();
  }
}
