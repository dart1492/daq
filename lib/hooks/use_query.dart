import 'dart:async';
import 'package:daq/daq.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Use query hook
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
  final context = useContext();

  final cache = useDAQCache();

  // DAQLogger is now used directly instead of daqDebugPrint

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

    if (context.mounted) {
      state.value = state.value.copyWith(
        status: QueryLoadingState.loading,
        error: null,
      );
    }

    try {
      final cacheKey = generateCacheKey(currentParameters);

      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedData = cache.getValue<TData>(cacheKey);
        if (cachedData != null) {
          DAQLogger.instance.query('Loading from cache: $cacheKey');

          if (context.mounted) {
            state.value = QueryState(
              status: QueryLoadingState.success,
              data: cachedData,
            );

            onSuccess?.call(cachedData);
          }

          return;
        }
      }

      late TData result;

      if (!enableCache) {
        DAQLogger.instance.query(
          'Executing the query function for: $cacheKey (NO CACHING)',
        );
        // if the caching is disabled for this query - just execute it, without adding the request to the duplication map.
        if (timeout != null) {
          result = await queryFn(currentParameters).timeout(timeout);
        } else {
          result = await queryFn(currentParameters);
        }
      } else {
        if (!cache.hasInflightRequest(cacheKey)) {
          DAQLogger.instance.query(
            'Executing the query function for: $cacheKey ()',
          );
        } else {
          DAQLogger.instance.query(
            'Request for: $cacheKey is already running - waiting to be completed',
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

      if (context.mounted) {
        state.value = QueryState(
          data: result,
          status: QueryLoadingState.success,
        );

        onSuccess?.call(result);
      }
    } on Object catch (error, stackTrace) {
      final transformedError = errorTransformer(error, stackTrace);

      DAQLogger.instance.error('Error occurred: $error', 'DAQ Query', error);

      if (context.mounted) {
        state.value = QueryState.error(transformedError);

        onError?.call(transformedError);
      }
    } finally {
      if (context.mounted) {
        onSettled?.call();
      }
    }
  }

  Future<void> refetch() async {
    // Clear cache for this query
    final cacheKey = generateCacheKey(parameters);

    DAQLogger.instance.query(
      'Refetching for the $cacheKey (Clearing cache and fetching again)',
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
        state.value.status != QueryLoadingState.loading) {
      fetch();
    }
    return null;
  }, [autoFetch]);

  // Subscribe to cache invalidation events
  useInvalidationSub(
    cache: cache,
    cacheKeys: [generateCacheKey(parameters)],
    cacheTags: cacheTags,
    logPrefix: 'query',
    onInvalidated: () {
      // Only refetch if we have data
      if (state.value.data != null) {
        fetch();
      }
    },
  );

  // Subscribe to cache mutation events
  useMutationSub<TData>(
    cache: cache,
    cacheKeys: [generateCacheKey(parameters)],
    cacheTags: cacheTags,
    logPrefix: 'query',
    onMutated: (mutatedData) {
      state.value = QueryState<TData, TError>.success(mutatedData);
      onSuccess?.call(mutatedData);
    },
  );

  return QueryController(
    state: state.value,
    fetch: fetch,
    refetch: refetch,
    updateParameters: updateParams,
  );
}
