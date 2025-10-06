// ignore_for_file: public_member_api_docs, sort_constructors_first
/// Core storage operations - so basically a wrapper around the Map object
class CacheStorage {
  final Map<String, CacheEntry> _cacheInstance = {};
  final Map<String, Set<String>> _keyTags = {}; // key -> tags

  /// Add value to cache with optional tags
  void addToCache<T>(String key, T value, {List<String>? tags}) {
    _cacheInstance[key] = CacheEntry<T>(
      value: value,
      lastWriteTime: DateTime.now(),
    );

    // Store tags for this key if provided
    if (tags != null && tags.isNotEmpty) {
      _keyTags[key] = tags.toSet();
    }
  }

  CacheEntry<T>? getEntry<T>(String key) {
    final entry = _cacheInstance[key];

    if (entry != null) {
      return entry as CacheEntry<T>;
    }

    return null;
  }

  /// Get value from cache
  T? getValue<T>(String key) {
    final entry = _cacheInstance[key];
    if (entry?.value is T?) {
      return entry?.value;
    }
    return null;
  }

  /// Check if key exists in cache
  bool hasKey(String key) {
    return _cacheInstance.containsKey(key);
  }

  /// Remove key from cache
  void removeKey(String key) {
    _cacheInstance.remove(key);
    _keyTags.remove(key);
  }

  /// Clear all cache data
  void clearAll() {
    _cacheInstance.clear();
    _keyTags.clear();
  }

  /// Get all cache keys
  List<String> get keys => _cacheInstance.keys.toList();

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

  /// Get all keys matching a pattern
  List<String> getKeysByPattern(String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    return _cacheInstance.keys.where((key) => regex.hasMatch(key)).toList();
  }

  /// Get all keys that have any of the provided tags
  List<String> getKeysByTags(List<String> tags) {
    final tagsSet = tags.toSet();
    final keysToReturn = <String>[];

    for (final entry in _keyTags.entries) {
      if (entry.value.any((tag) => tagsSet.contains(tag))) {
        keysToReturn.add(entry.key);
      }
    }

    return keysToReturn;
  }

  /// Update tags for a key
  void updateTagsForKey(String key, List<String> tags) {
    if (tags.isNotEmpty) {
      _keyTags[key] = tags.toSet();
    }
  }

  /// Get raw cache instance (for internal use)
  Map<String, dynamic> get cacheInstance => _cacheInstance;

  /// Get raw key tags (for internal use)
  Map<String, Set<String>> get keyTags => _keyTags;
}

class CacheEntry<T> {
  DateTime lastWriteTime;
  T value;
  CacheEntry({required this.lastWriteTime, required this.value});

  CacheEntry<T> copyWith({DateTime? lastWriteTime, T? value}) {
    return CacheEntry<T>(
      lastWriteTime: lastWriteTime ?? this.lastWriteTime,
      value: value ?? this.value,
    );
  }
}
