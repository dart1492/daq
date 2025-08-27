/// Cache invalidation event that notifies listeners about invalidated cache keys.
class CacheInvalidationEvent {
  const CacheInvalidationEvent({
    required this.invalidatedKeys,
    this.pattern,
    this.tags,
  });

  final List<String> invalidatedKeys;
  final String? pattern;
  final List<String>? tags;
}

/// Cache mutation event that notifies listeners about updated cache data
class CacheMutationEvent {
  const CacheMutationEvent({
    required this.mutatedKeys,
    required this.mutatedData,
    this.pattern,
    this.tags,
  });

  final List<String> mutatedKeys;
  final Map<String, dynamic> mutatedData; // key -> new data
  final String? pattern;
  final List<String>? tags;
}
