import 'dart:async';
import 'package:daq/darts_async_query.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Hook for simple single object queries with caching
///
/// Usage:
/// ```dart
/// final userQuery = useQuery<User, int>(
///   queryFn: (userId) => api.getUser(userId),
///   cachePrefix: 'user',
///   variables: 123,
///   onSuccess: (user) {
///     debugPrint('User loaded: ${user.name}');
///   },
///   onError: (error) {
///     showSnackBar('Failed to load user: ${error.message}');
///   },
/// );
///
/// // Access state
/// if (userQuery.isLoading) { ... }
/// if (userQuery.isSuccess) { ... }
/// final user = userQuery.data;
/// ```
QueryController<TData, TParams, TError> useQuery<TData, TParams, TError>({
  required Future<TData> Function(TParams variables) queryFn,

  required TError Function(Object, StackTrace) errorTransformer,

  required String cachePrefix,

  required TParams parameters,

  void Function(TParams parameters)? onLoading,
  void Function(TData data)? onSuccess,
  void Function(TError error)? onError,
  void Function()? onSettled,

  bool enableCache = true,

  /// Shows if we should cache the prefix + parameters unique hash. If this is false- we only cache for the prefix and the parameters can come and go.
  bool enableCacheForParameters = true,

  bool autoFetch = true,

  Duration? timeout,

  List<String>? cacheTags,
}) {
  final cache = useDAQCache();

  final daqDebugPrint = useDAQDebug();

  final state = useState<QueryState<TData, TError>>(QueryState.initial());

  String generateCacheKey(TParams variables) {
    if (enableCacheForParameters) {
      return '${cachePrefix}_${variables.hashCode}';
    } else {
      return cachePrefix;
    }
  }

  Future<void> fetch({TParams? newParameters}) async {
    final currentParameters = newParameters ?? parameters;

    onLoading?.call(currentParameters);

    state.value = state.value.copyWith(
      status: QueryStatus.loading,
      error: null,
    );

    try {
      final cacheKey = generateCacheKey(currentParameters);

      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedData = cache.getValue<TData>(cacheKey);
        if (cachedData != null) {
          daqDebugPrint('[DAQ Query] Loading from cache: $cacheKey');

          state.value = QueryState(
            status: QueryStatus.success,
            data: cachedData,
          );

          onSuccess?.call(cachedData);
          return;
        }
      }

      late TData result;

      if (!enableCache) {
        daqDebugPrint(
          '[DAQ Query]  Executing the query function for: $cacheKey (NO CACHING)',
        );
        // if the caching is disabled for this query - just execute it, without adding the request to the duplication map.
        if (timeout != null) {
          result = await queryFn(currentParameters).timeout(timeout);
        } else {
          result = await queryFn(currentParameters);
        }
      } else {
        if (!cache.hasInflightRequest(cacheKey)) {
          daqDebugPrint(
            '[DAQ Query]  Executing the query function for: $cacheKey ()',
          );
        } else {
          daqDebugPrint(
            '[DAQ Query]  Request for: $cacheKey is already running - waiting to be completed',
          );
        }

        // perform the request by first checking if it's running already
        result = await cache.executeWithDeduplication<TData>(
          cacheKey,
          () async {
            if (timeout != null) {
              return await queryFn(currentParameters).timeout(timeout);
            } else {
              return await queryFn(currentParameters);
            }
          },
          tags: cacheTags,
        );
      }

      state.value = QueryState(data: result, status: QueryStatus.success);

      onSuccess?.call(result);
    } on Object catch (error, stackTrace) {
      final transformedError = errorTransformer(error, stackTrace);

      state.value = QueryState.error(transformedError);

      daqDebugPrint('[DAQ Query] Error occurred: $error');

      onError?.call(transformedError);
    } finally {
      onSettled?.call();
    }
  }

  Future<void> refetch() async {
    // Clear cache for this query
    final cacheKey = generateCacheKey(parameters);

    daqDebugPrint(
      '[DAQ Query]  Refetching  for the $cacheKey (Clearing cache and fetching again)',
    );

    if (cache.hasKey(cacheKey)) {
      cache.removeKey(cacheKey);
    }

    await fetch();
  }

  /// Refetch with the new parameters. Won't refetch if the [enableCacheForParameters] is set to false.
  void updateParams(TParams newParameters) {
    if (newParameters != parameters) {
      fetch(newParameters: newParameters);
    }
  }

  // Auto-fetch on mount hook
  useEffect(() {
    if (autoFetch &&
        state.value.data == null &&
        state.value.status != QueryStatus.loading) {
      fetch();
    }
    return null;
  }, [autoFetch]);

  useEffect(() {
    late StreamSubscription invalidationSubscription;

    invalidationSubscription = cache.invalidationStream.listen((event) {
      final currentCacheKey = generateCacheKey(parameters);

      bool shouldRefetch = false;

      // Direct key match
      if (event.invalidatedKeys.contains(currentCacheKey)) {
        shouldRefetch = true;
      }

      // Pattern match
      if (!shouldRefetch && event.pattern != null) {
        final regex = RegExp(event.pattern!.replaceAll('*', '.*'));
        if (regex.hasMatch(currentCacheKey)) {
          shouldRefetch = true;
        }
      }

      // Tag match
      if (!shouldRefetch && event.tags != null && cacheTags != null) {
        final eventTagsSet = event.tags!.toSet();
        final cacheTagsSet = cacheTags.toSet();
        if (eventTagsSet.intersection(cacheTagsSet).isNotEmpty) {
          shouldRefetch = true;
        }
      }

      // Refetch if invalidated and we have data
      if (shouldRefetch && state.value.data != null) {
        daqDebugPrint(
          '[DAQ Query] Auto-refetching due to cache invalidation: $currentCacheKey',
        );

        fetch();
      }
    });

    return invalidationSubscription.cancel;
  }, [cache, cachePrefix, parameters, cacheTags]);

  // Subscribe to cache mutation events
  useEffect(() {
    late StreamSubscription mutationSubscription;

    mutationSubscription = cache.mutationStream.listen((event) {
      final currentCacheKey = generateCacheKey(parameters);

      // Check if our cache key was involved in the mutation. This is to filter out unnecessary updates
      bool shouldUpdate = false;
      dynamic newData;

      // Direct key match
      if (event.mutatedKeys.contains(currentCacheKey)) {
        shouldUpdate = true;
        newData = event.mutatedData[currentCacheKey];
      }

      // Pattern match
      if (!shouldUpdate && event.pattern != null) {
        final regex = RegExp(event.pattern!.replaceAll('*', '.*'));
        if (regex.hasMatch(currentCacheKey)) {
          // Find the mutated data for this key
          for (final key in event.mutatedKeys) {
            if (key == currentCacheKey) {
              shouldUpdate = true;
              newData = event.mutatedData[key];
              break;
            }
          }
        }
      }

      // Tag match
      if (!shouldUpdate && event.tags != null && cacheTags != null) {
        final eventTagsSet = event.tags!.toSet();
        final cacheTagsSet = cacheTags.toSet();
        if (eventTagsSet.intersection(cacheTagsSet).isNotEmpty) {
          // Check if our specific key was mutated
          if (event.mutatedKeys.contains(currentCacheKey)) {
            shouldUpdate = true;
            newData = event.mutatedData[currentCacheKey];
          }
        }
      }

      // Update state with new data if our cache was mutated
      if (shouldUpdate && newData != null) {
        daqDebugPrint(
          '[DAQ Query] Auto-updating due to cache mutation: $currentCacheKey',
        );

        state.value = QueryState<TData, TError>.success(newData);

        onSuccess?.call(newData);
      }
    });

    return mutationSubscription.cancel;
  }, [cache, cachePrefix, parameters, cacheTags]);

  return QueryController._(
    state: state.value,
    fetch: fetch,
    refetch: refetch,
    updateParameters: updateParams,
  );
}

/// Controller for simple queries
class QueryController<TData, TParams, TError> {
  const QueryController._({
    required this.state,
    required this.fetch,
    required this.refetch,
    required this.updateParameters,
  });

  final QueryState<TData, TError> state;
  final Future<void> Function({TParams? newParameters}) fetch;
  final Future<void> Function() refetch;
  final void Function(TParams newParameters) updateParameters;

  // Getters for common state checks
  bool get isLoading => state.status == QueryStatus.loading;
  bool get isSuccess => state.status == QueryStatus.success;
  bool get hasError => state.status == QueryStatus.error;
  bool get isIdle => state.status == QueryStatus.idle;

  TData? get data => state.data;
  TError? get error => state.error;
  QueryStatus get status => state.status;

  // Actions
  Future<void> fetchData({TParams? newParameters}) =>
      fetch(newParameters: newParameters);

  Future<void> refetchData() => refetch();

  void updateQueryVariables(TParams newVariables) =>
      updateParameters(newVariables);
}

/// Represents the state of a simple query
class QueryState<TData, TError> {
  const QueryState({required this.status, this.data, this.error});
  const QueryState._({required this.status, this.data, this.error});

  factory QueryState.initial() => const QueryState._(status: QueryStatus.idle);

  factory QueryState.error(TError error) =>
      QueryState._(status: QueryStatus.error, error: error, data: null);

  factory QueryState.success(TData data) =>
      QueryState._(status: QueryStatus.success, error: null, data: data);

  final QueryStatus status;
  final TData? data;
  final TError? error;

  QueryState<TData, TError> copyWith({
    QueryStatus? status,
    TData? data,
    TError? error,
  }) {
    return QueryState._(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

/// Enum representing the status of a simple query
enum QueryStatus { idle, loading, success, error }

/// Extension to provide convenient methods for query status
extension QueryStatusX on QueryStatus {
  bool get isIdle => this == QueryStatus.idle;
  bool get isLoading => this == QueryStatus.loading;
  bool get isSuccess => this == QueryStatus.success;
  bool get isError => this == QueryStatus.error;
}
