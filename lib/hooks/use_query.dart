import 'dart:async';
import 'package:daq/daq.dart';
import 'package:flutter/material.dart';
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

  /// An app lifecycle hook that allows to perform a refetch when the app is coming from an inactive state (when the user has switched to another app, or hid this one, etc.)
  /// Be default is turned off.
  bool? refetchOnAppFromInactiveToResumed,

  /// to disable timer that periodically re-fetches when the cache si no longer valid.
  bool? enablePeriodicTTLRefetch,
}) {
  final context = useContext();

  final cache = useDAQCache();

  final state = useState<QueryState<TData, TError, TParams>>(
    QueryState(status: QueryLoadingState.idle, params: parameters),
  );

  void mountGate(Function fn) {
    if (!context.mounted) return;

    fn();
  }

  String generateCacheKey(TParams variables) {
    return '${cachePrefix}_${variables.hashCode}';
  }

  Future<void> fetch({TParams? newParameters}) async {
    final currentParameters = newParameters ?? state.value.params;

    mountGate(() {
      onLoading?.call(currentParameters);

      state.value = state.value.copyWith(
        status: QueryLoadingState.loading,
        error: null,
        params: currentParameters,
      );
    });

    try {
      final cacheKey = generateCacheKey(currentParameters);

      // cache is enabled and an entry is present
      if (enableCache && cache.hasKey(cacheKey)) {
        final cacheEntry = cache.getEntry<TData>(cacheKey)!;

        final globalTTL = cache.config.ttlConfig.defaultQueryTTL;

        final usedTTL = timeToLive ?? globalTTL;

        bool isAlive = DAQUtilFunctions.checkIsAlive(
          lastWrite: cacheEntry.lastWriteTime,
          ttl: usedTTL,
        );

        if (!isAlive) {
          DAQLogger.instance.query(
            'Cache for the: $cacheKey has outlived its time.',
          );
        }

        if (isAlive) {
          DAQLogger.instance.query('Loading from cache: $cacheKey');

          mountGate(() {
            state.value = QueryState<TData, TError, TParams>(
              status: QueryLoadingState.success,
              data: cacheEntry.value,
              params: currentParameters,
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
        result = await queryFn(currentParameters);
      } else {
        DAQLogger.instance.query(
          'Request for: $cacheKey. Time to live: ${timeToLive ?? cache.config.ttlConfig.defaultQueryTTL}',
        );

        result = await cache.executeWithDeduplication<TData>(
          cacheKey,
          () async {
            return await queryFn(currentParameters);
          },
          tags: cacheTags,
        );
      }

      cache.config.globalHandlersConfig?.onSuccess?.call(
        GlobalSuccessEvent(type: GlobalEvenTypes.query, data: result),
      );

      mountGate(() {
        state.value = QueryState<TData, TError, TParams>(
          data: result,
          status: QueryLoadingState.success,
          params: currentParameters,
        );

        onSuccess?.call(result);
      });
    } on Object catch (error, stackTrace) {
      final transformedError = errorTransformer(error, stackTrace);

      DAQLogger.instance.error('Error occurred: $error', 'DAQ Query', error);

      cache.config.globalHandlersConfig?.onError?.call(
        GlobalErrorEvent(type: GlobalEvenTypes.query, data: transformedError),
      );

      mountGate(() {
        state.value = QueryState.error(transformedError, state.value.params);

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
    final cacheKey = generateCacheKey(state.value.params!);

    DAQLogger.instance.query(
      'Refetching for the $cacheKey (Clearing cache and fetching again)',
    );

    if (cache.hasKey(cacheKey)) {
      cache.removeKey(cacheKey);
    }

    await fetch();
  }

  void updateParams(TParams newParameters) {
    if (newParameters != state.value.params) {
      fetch(newParameters: newParameters);
    }
  }

  if (refetchOnAppFromInactiveToResumed == true) {
    useOnAppLifecycleStateChange((prevState, newState) {
      // if the user has switched to some other app and came back to this one - we need to refetch whats on the screen
      if (prevState == AppLifecycleState.inactive &&
          newState == AppLifecycleState.resumed) {
        refetch();
      }
    });
  }

  // Subscribe to cache invalidation events
  useInvalidationSub(
    cache: cache,
    cacheKeys: [generateCacheKey(state.value.params)],
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
    cacheKeys: [generateCacheKey(state.value.params)],
    cacheTags: cacheTags,
    logPrefix: 'query',
    onMutated: (mutatedData) {
      state.value = QueryState<TData, TError, TParams>(
        status: QueryLoadingState.success,
        data: mutatedData,
        params: state.value.params,
      );
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
