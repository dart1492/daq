import 'dart:async';

import 'package:daq/utils/daq_cache/daq_config/daq_config.dart';
import 'package:daq/utils/daq_cache/events.dart';
import 'package:daq/utils/daq_logger.dart';
import 'cache_parts/cache_storage.dart';
import 'cache_parts/cache_invalidator.dart';
import 'cache_parts/cache_mutator.dart';
import 'cache_parts/request_deduplicator.dart';

class DAQCache {
  DAQCache({required this.config}) {
    // Initialize the logger with the config setting
    DAQLogger.instance.setEnabled(config.enableLogging);

    // Initialize components
    _cacheStorage = CacheStorage();
    _cacheInvalidator = CacheInvalidator(_cacheStorage);
    _cacheMutator = CacheMutator(_cacheStorage);
    _requestDeduplicator = RequestDeduplicator();
  }

  final DAQConfig config;

  late final CacheStorage _cacheStorage;
  late final CacheInvalidator _cacheInvalidator;
  late final CacheMutator _cacheMutator;
  late final RequestDeduplicator _requestDeduplicator;

  /// Stream of cache invalidation events
  Stream<CacheInvalidationEvent> get invalidationStream =>
      _cacheInvalidator.invalidationStream;

  /// Stream of cache mutation events
  Stream<CacheMutationEvent> get mutationStream => _cacheMutator.mutationStream;

  // =================== CACHE STORAGE DELEGATION ===================

  void addToCache<T>(String key, T value, {List<String>? tags}) {
    _cacheStorage.addToCache<T>(key, value, tags: tags);
  }

  CacheEntry<T>? getEntry<T>(String key) {
    return _cacheStorage.getEntry<T>(key);
  }

  T? getValue<T>(String key) {
    return _cacheStorage.getValue<T>(key);
  }

  bool hasKey(String key) {
    return _cacheStorage.hasKey(key);
  }

  void removeKey(String key) {
    _cacheStorage.removeKey(key);
    _requestDeduplicator.removeInflightRequest(key);
  }

  void clearAll() {
    _cacheStorage.clearAll();
    _requestDeduplicator.clearAllInflightRequests();
  }

  List<String> get keys => _cacheStorage.keys;

  Set<String>? getTagsForKey(String key) {
    return _cacheStorage.getTagsForKey(key);
  }

  List<String> getKeysByTag(String tag) {
    return _cacheStorage.getKeysByTag(tag);
  }

  List<String> getKeysByPattern(String pattern) {
    return _cacheStorage.getKeysByPattern(pattern);
  }

  // =================== REQUEST DEDUPLICATION ===================

  bool hasInflightRequest(String key) {
    return _requestDeduplicator.hasInflightRequest(key);
  }

  Future<T>? getInflightRequest<T>(String key) {
    return _requestDeduplicator.getInflightRequest<T>(key);
  }

  Future<T> executeWithDeduplication<T>(
    String key,
    Future<T> Function() requestFn, {
    List<String>? tags,
    bool? enableCaching,
  }) async {
    final result = await _requestDeduplicator.executeWithDeduplication(
      key,
      requestFn,
    );

    addToCache(key, result, tags: tags);

    return result;
  }

  // =================== CACHE INVALIDATION ===================

  void invalidateByPattern(String pattern, {bool emitEvent = true}) {
    _cacheInvalidator.invalidateByPattern(pattern, emitEvent: emitEvent);
  }

  void invalidateByTags(List<String> tags, {bool emitEvent = true}) {
    _cacheInvalidator.invalidateByTags(tags, emitEvent: emitEvent);
  }

  void invalidateKeys(List<String> keys, {bool emitEvent = true}) {
    _cacheInvalidator.invalidateKeys(keys, emitEvent: emitEvent);
  }

  // =================== CACHE MUTATION ===================

  void updateCache<T>(
    String key,
    T Function(T?) updater, {
    List<String>? tags,
    bool emitEvent = true,
  }) {
    _cacheMutator.updateCacheBySingleKey<T>(
      key,
      updater(_cacheStorage.getValue(key)),
      tags: tags,
      emitEvent: emitEvent,
    );
  }

  void updateCacheBatch(
    List<String> mutatedKeys,
    Map<String, dynamic> mutatedData, {
    bool emitEvent = true,
  }) {
    _cacheMutator.updateCacheBatch(
      mutatedKeys,
      mutatedData,
      emitEvent: emitEvent,
    );
  }

  // =================== RESOURCE DISPOSAL ===================

  /// Dispose resources
  void dispose() {
    _requestDeduplicator.clearAllInflightRequests();
    _cacheInvalidator.dispose();
    _cacheMutator.dispose();
  }
}
