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

  bool autoFetch = true,

  List<String>? cacheTags,

  /// Optional override of the default time to live for the useQuery, that is provided by DAQConfig.
  /// If both are null the cache lives on forever.
  Duration? timeToLive,

  /// to disable timer that periodically re-fetches when the cache si no longer valid.
  bool? enablePeriodicTTLRefetch,
}) {
  final context = useContext();

  final cache = useDAQCache();

  // DAQLogger is now used directly instead of daqDebugPrint

  final state = useState<QueryState<TData, TError>>(QueryState.initial());

  void mountGate(Function fn) {
    if (!context.mounted) return;

    fn();
  }

  String generateCacheKey(TParams variables) {
    return '${cachePrefix}_${variables.hashCode}';
  }

  Future<void> fetch({TParams? newParameters}) async {
    final currentParameters = newParameters ?? parameters;

    mountGate(() {
      onLoading?.call(currentParameters);

      state.value = state.value.copyWith(
        status: QueryLoadingState.loading,
        error: null,
      );
    });

    try {
      final cacheKey = generateCacheKey(currentParameters);

      // cache is enabled and an entry is present
      if (enableCache && cache.hasKey(cacheKey)) {
        final cacheEntry = cache.getEntry<TData>(cacheKey)!;

        bool isAlive = false;

        final globalTTL = cache.config.ttlConfig?.defaultQueryTTL;

        final usedTTL = globalTTL ?? timeToLive;

        if (usedTTL != null) {
          DateTime now = DateTime.now();

          if (now.difference(cacheEntry.lastWriteTime) < usedTTL) {
            isAlive = true;
          } else {
            DAQLogger.instance.query(
              'Cache for the: $cacheKey has outlived its time.',
            );
          }
        }

        if (isAlive) {
          DAQLogger.instance.query('Loading from cache: $cacheKey');

          mountGate(() {
            state.value = QueryState(
              status: QueryLoadingState.success,
              data: cacheEntry.value,
            );

            onSuccess?.call(cacheEntry.value);
          });

          return;
        }
      }

      late TData result;

      if (!enableCache) {
        DAQLogger.instance.query(
          'Executing the query function for: $cacheKey (NO CACHING)',
        );
        // if the caching is disabled for this query - just execute it, without adding the request to the duplication map.
        await queryFn(currentParameters);
      } else {
        if (!cache.hasInflightRequest(cacheKey)) {
          DAQLogger.instance.query(
            'Executing the query function for: $cacheKey (). Time to live: ${timeToLive ?? cache.config.ttlConfig.defaultQueryTTL}',
          );
        } else {
          DAQLogger.instance.query(
            'Request for: $cacheKey is already running - waiting to be completed',
          );
        }

        // check if the request is running already
        result = await cache.executeWithDeduplication<TData>(
          cacheKey,
          () async {
            return await queryFn(currentParameters);
          },
          tags: cacheTags,
        );
      }

      mountGate(() {
        state.value = QueryState(
          data: result,
          status: QueryLoadingState.success,
        );

        onSuccess?.call(result);
      });
    } on Object catch (error, stackTrace) {
      final transformedError = errorTransformer(error, stackTrace);

      DAQLogger.instance.error('Error occurred: $error', 'DAQ Query', error);

      mountGate(() {
        state.value = QueryState.error(transformedError);

        onError?.call(transformedError);
      });
    } finally {
      mountGate(() {
        onSettled?.call();
      });
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

  void updateParams(TParams newParameters) {
    if (newParameters != parameters) {
      fetch(newParameters: newParameters);
    }
  }

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

  final isTTLRefreshEnabled =
      enablePeriodicTTLRefetch ??
      cache.config.ttlConfig.enablePeriodicTTLRefresh;

  if (isTTLRefreshEnabled) {
    if (cache.config.ttlConfig.defaultQueryTTL != null || timeToLive != null) {
      final realTTL = (timeToLive ?? cache.config.ttlConfig.defaultQueryTTL)!;

      useTTLSub(
        cache: cache,
        cacheKeys: [generateCacheKey(parameters)],
        logPrefix: 'query',
        timeToLive: realTTL,
        checkInterval: realTTL + Duration(seconds: 5), // a slight increase,
        onExpired: () {
          // Only refetch if we have data
          if (state.value.data != null) {
            fetch();
          }
        },
      );
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

  return QueryController(
    state: state.value,
    fetch: fetch,
    refetch: refetch,
    updateParameters: updateParams,
  );
}
