// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:daq/daq.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Use infinite query hook
InfiniteQueryController<TData, TParams, TError>
useInfiniteQuery<TData, TParams, TError>({
  required Future<DAQInfiniteQueryResponse<TData>> Function(
    TParams params,
    int page,
    int pageSize,
  )
  fetcher,

  required TError Function(Object, StackTrace) errorTransformer,

  required String cachePrefix,

  required TParams initialParameters,

  int pageSize = 20,

  bool enableCache = true,

  bool autoFetch = true,

  List<String>? cacheTags,

  void Function(TParams parameters, DAQCache cacheInstance)? onLoading,

  void Function(DAQInfiniteQueryResponse<TData>, DAQCache cacheInstance)?
  onSuccess,

  void Function(TError error, DAQCache cacheInstance)? onError,

  /// Optional override of the default time to live for the useQuery, that is provided by DAQConfig.
  /// If both are null the cache lives on forever.
  Duration? timeToLive,

  /// An app lifecycle hook that allows to perform a refetch when the app is coming from an inactive state (when the user has switched to another app, or hid this one, etc.)
  /// Be default is turned off.
  bool? refetchOnAppFromInactiveToResumed,

  /// to disable timer that periodically re-fetches when the cache si no longer valid.
  /// This value overrides the global value, set in the [DAQConfig]
  bool? enablePeriodicTTLRefetch,
}) {
  final context = useContext();

  final state = useState<InfiniteQueryState<TData, TParams, TError>>(
    InfiniteQueryState(data: [], parameters: initialParameters),
  );

  final cache = useDAQCache();

  // Generate cache key based on cache prefix, filters and page
  String generateCacheKey(TParams? filters) {
    return '${cachePrefix}_${filters.hashCode}';
  }

  // Fetch first page (reset pagination)
  Future<void> fetch({TParams? newParameters}) async {
    if (context.mounted) {
      state.value = state.value.copyWith(
        loadingState: InfiniteQueryLoadingState.loading,
        parameters: newParameters ?? state.value.parameters,
        currentPage: 1,
      );

      onLoading?.call(state.value.parameters, cache);
    }

    try {
      final cacheKey = generateCacheKey(state.value.parameters);

      // Check cache first
      if (enableCache && cache.hasKey(cacheKey)) {
        final cacheEntry = cache.getEntry<DAQInfiniteQueryResponse<TData>>(
          cacheKey,
        )!;

        bool isAlive = true;

        final globalTTL = cache.config.ttlConfig.defaultQueryTTL;

        final usedTTL = timeToLive ?? globalTTL;

        // check if this entry is viable
        if (usedTTL != null) {
          DateTime now = DateTime.now();

          if (now.difference(cacheEntry.lastWriteTime) < usedTTL) {
            isAlive = true;
          } else {
            isAlive = false;
            DAQLogger.instance.infiniteQuery(
              'Cache for the: $cacheKey has outlived its time.',
            );
          }
        }

        if (isAlive) {
          final cachedResponse = cacheEntry.value;
          DAQLogger.instance.infiniteQuery('Loading from cache: $cacheKey');

          state.value = state.value.copyWith(
            data: cachedResponse.items,
            loadingState: InfiniteQueryLoadingState.success,
            totalPages: cachedResponse.totalPages,
            totalItems: cachedResponse.totalItems,
            hasNextPage: cachedResponse.hasNextPage,
            currentPage: cachedResponse.currentPage,
          );

          return;
        }
      }

      DAQLogger.instance.infiniteQuery(
        'Fetching from API for: $cacheKey. Time to live: ${timeToLive ?? cache.config.ttlConfig.defaultInfiniteQueryTTL} ',
      );
      final result = await fetcher(state.value.parameters, 1, pageSize);

      // Cache the result
      if (enableCache) {
        cache.addToCache(cacheKey, result, tags: cacheTags);
      }

      if (context.mounted) {
        state.value = state.value.copyWith(
          data: result.items,
          loadingState: InfiniteQueryLoadingState.success,
          totalPages: result.totalPages,
          totalItems: result.totalItems,
          hasNextPage: result.hasNextPage,
        );

        onSuccess?.call(result, cache);
      }
    } on Object catch (error, stackTrace) {
      DAQLogger.instance.error(
        'Error occurred: $error',
        'DAQ Infinite Query',
        error,
      );

      final transformedError = errorTransformer(error, stackTrace);

      if (context.mounted) {
        state.value = state.value.copyWith(
          loadingState: InfiniteQueryLoadingState.error,
          error: transformedError,
        );

        onError?.call(transformedError, cache);
      }
    }
  }

  // Fetch next page (append to existing data). So it will not check cache, because we are not caching each page.
  // This command will only fetch the next page for the list - so it assumes that the first one has been loaded already.
  Future<void> fetchNextPage() async {
    if (!state.value.hasNextPage ||
        state.value.loadingState == InfiniteQueryLoadingState.loadingMore) {
      return;
    }

    final nextPage = state.value.currentPage + 1;

    if (context.mounted) {
      state.value = state.value.copyWith(
        loadingState: InfiniteQueryLoadingState.loadingMore,
      );
    }

    try {
      DAQLogger.instance.infiniteQuery(
        'Loading next page from API for: ${generateCacheKey(state.value.parameters)}',
      );

      final result = await fetcher(state.value.parameters, nextPage, pageSize);

      final mergedAllItemsList = List<TData>.from(state.value.data)
        ..addAll(result.items);

      // Cache the result
      if (enableCache) {
        final cacheKey = generateCacheKey(state.value.parameters);

        final cachedInfiniteResponse = cache
            .getValue<DAQInfiniteQueryResponse<TData>>(cacheKey);

        cache.updateCache(cacheKey, (prevResponse) {
          return cachedInfiniteResponse!.copyWith(
            items: mergedAllItemsList,
            totalItems: result.totalItems,
            totalPages: result.totalPages,
            hasNextPage: result.hasNextPage,
            currentPage: nextPage,
          );
        });
      }
    } on Object catch (error, stackTrace) {
      DAQLogger.instance.error(
        'Error occurred: $error',
        'DAQ Infinite Query',
        error,
      );

      final transformedError = errorTransformer(error, stackTrace);

      if (context.mounted) {
        state.value = state.value.copyWith(
          loadingState: InfiniteQueryLoadingState.error,
          error: transformedError,
        );
      }
    }
  }

  // Refetch from ground up (clear cache and start fresh)
  Future<void> refetchFromStart({TParams? newParameters}) async {
    DAQLogger.instance.infiniteQuery(
      'Refetching the whole list from the start',
    );

    // Clear cache for this filter set
    final keysToRemove = cache.keys
        .where(
          (key) => key.startsWith(
            '${cachePrefix}_${state.value.parameters.hashCode}',
          ),
        )
        .toList();

    for (final key in keysToRemove) {
      cache.removeKey(key);
    }

    await fetch(newParameters: newParameters);
  }

  // Update filters and refetch
  void updateParameters(TParams newParameters) {
    if (newParameters != state.value.parameters) {
      fetch(newParameters: newParameters);
    }
  }

  if (refetchOnAppFromInactiveToResumed == true) {
    useOnAppLifecycleStateChange((prevState, newState) {
      // if the user has switched to some other app and came back to this one - we need to refetch whats on the screen
      if (prevState == AppLifecycleState.inactive &&
          newState == AppLifecycleState.resumed) {
        refetchFromStart();
      }
    });
  }

  // invalidation sub
  useInvalidationSub(
    cache: cache,
    keyPattern: '${cachePrefix}_*',
    cacheKeys: [generateCacheKey(state.value.parameters)],
    cacheTags: cacheTags,
    onInvalidated: () {
      if (state.value.data.isNotEmpty) {
        refetchFromStart();
      }
    },
  );

  // Subscribe to cache mutation events
  useMutationSub<DAQInfiniteQueryResponse<TData>>(
    cache: cache,
    cacheKeys: [generateCacheKey(state.value.parameters)],
    cacheTags: cacheTags,
    logPrefix: 'infinite query',
    onMutated: (mutatedData) {
      if (context.mounted) {
        state.value = state.value.copyWith(
          data: mutatedData.items,
          totalItems: mutatedData.totalItems,
          totalPages: mutatedData.totalPages,
          hasNextPage: mutatedData.hasNextPage,
          currentPage: mutatedData.currentPage,
          loadingState: InfiniteQueryLoadingState.success,
        );
      }
    },
  );

  final isTTLRefreshEnabled =
      enablePeriodicTTLRefetch ??
      cache.config.ttlConfig.enablePeriodicTTLRefresh;

  if (isTTLRefreshEnabled) {
    if (cache.config.ttlConfig.defaultInfiniteQueryTTL != null ||
        timeToLive != null) {
      final realTTL =
          (timeToLive ?? cache.config.ttlConfig.defaultInfiniteQueryTTL)!;

      useTTLSub(
        cache: cache,
        cacheKeys: [generateCacheKey(state.value.parameters)],
        timeToLive: realTTL,
        checkInterval: realTTL + Duration(seconds: 5), // a slight increase
        onExpired: () {
          refetchFromStart();
        },
      );
    }
  }

  // Auto-fetch on mount
  useEffect(() {
    if (autoFetch && state.value.data.isEmpty && !state.value.isLoading) {
      fetch();
    }
    return null;
  }, [autoFetch]);

  // Check if can load more
  final canLoadMore =
      state.value.hasNextPage &&
      state.value.loadingState != InfiniteQueryLoadingState.loadingMore;

  return InfiniteQueryController(
    state.value,
    fetch,
    fetchNextPage,
    refetchFromStart,
    updateParameters,
    canLoadMore,
  );
}
