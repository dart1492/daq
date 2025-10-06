// ignore_for_file: public_member_api_docs, sort_constructors_first
/// Configuration class for DAQ cache
class DAQConfig {
  /// DISABLED LOGGING BY DEFAULT
  final bool enableLogging;

  final CacheTTLConfig ttlConfig;

  DAQConfig({bool? enableLogging, CacheTTLConfig? ttlConfig})
    : enableLogging = enableLogging ?? false,
      ttlConfig = ttlConfig ?? CacheTTLConfig();
}

// TTL related configurations
class CacheTTLConfig {
  Duration? defaultInfiniteQueryTTL;

  /// Global cache entry ttl for all [useQuery] instances.
  Duration? defaultQueryTTL;

  /// IF all reactive refreshing on TTL exploration should be disabled.
  /// By default it is enabled - meaning there is an internal timer on each [useQuery], [useInfiniteQuery] that would
  /// perform a refetch each [x] interval (if it was actually set globally in this config, or for the particular query.
  bool enablePeriodicTTLRefresh;

  CacheTTLConfig({
    this.defaultInfiniteQueryTTL,
    this.defaultQueryTTL,
    bool? enablePeriodicTTLRefresh,
  }) : enablePeriodicTTLRefresh = enablePeriodicTTLRefresh ?? true;
}
