import 'package:daq/daq.dart';
import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Paginated query hook
PaginatedQueryController<TData, TParams, TError>
usePaginatedQuery<TData, TParams, TError>({
  required Future<DAQPaginatedQueryResponse<TData>> Function(
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
}) {
  final context = useContext();

  final state = useState<PaginatedQueryState<TData, TParams, TError>>(
    PaginatedQueryState(data: [], parameters: initialParameters),
  );

  final cache = useDAQCache();

  // Generate cache key based on cache prefix, filters and page
  String generateCacheKey(TParams? filters, int page) {
    return '${cachePrefix}_${filters.hashCode}_page_$page';
  }

  // Fetch first page (reset pagination)
  Future<void> fetch({TParams? newParameters}) async {
    if (context.mounted) {
      state.value = state.value.copyWith(
        loadingState: PaginatedQueryLoadingState.loading,
        parameters: newParameters ?? state.value.parameters,
        currentPage: 1,
      );
    }

    try {
      final cacheKey = generateCacheKey(state.value.parameters, 1);

      // Check cache first
      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedResponse = cache.getValue<DAQPaginatedQueryResponse<TData>>(
          cacheKey,
        );

        if (cachedResponse != null) {
          DAQLogger.instance.paginatedQuery('Loading from cache: $cacheKey');
          state.value = state.value.copyWith(
            data: cachedResponse.items,
            loadingState: PaginatedQueryLoadingState.success,
            totalPages: cachedResponse.totalPages,
            totalItems: cachedResponse.totalItems,
            hasNextPage: cachedResponse.hasNextPage,
          );
          return;
        }
      }

      DAQLogger.instance.paginatedQuery('Fetching from API: $cacheKey');
      final result = await fetcher(state.value.parameters, 1, pageSize);

      // Cache the result
      if (enableCache) {
        cache.addToCache(cacheKey, result, tags: cacheTags);
      }

      if (context.mounted) {
        state.value = state.value.copyWith(
          data: result.items,
          loadingState: PaginatedQueryLoadingState.success,
          totalPages: result.totalPages,
          totalItems: result.totalItems,
          hasNextPage: result.hasNextPage,
        );
      }
    } on Object catch (error, stackTrace) {
      DAQLogger.instance.error(
        'Error occurred: $error',
        'DAQ Paginated Query',
        error,
      );

      final transformedError = errorTransformer(error, stackTrace);

      if (context.mounted) {
        state.value = state.value.copyWith(
          loadingState: PaginatedQueryLoadingState.error,
          error: transformedError,
        );
      }
    }
  }

  // Fetch next page (append to existing data)
  Future<void> fetchNextPage() async {
    if (!state.value.hasNextPage ||
        state.value.loadingState == PaginatedQueryLoadingState.loadingMore) {
      return;
    }

    final nextPage = state.value.currentPage + 1;

    if (context.mounted) {
      state.value = state.value.copyWith(
        loadingState: PaginatedQueryLoadingState.loadingMore,
      );
    }

    try {
      final cacheKey = generateCacheKey(state.value.parameters, nextPage);

      // Check cache first
      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedResponse = cache.getValue<DAQPaginatedQueryResponse<TData>>(
          cacheKey,
        );
        if (cachedResponse != null) {
          DAQLogger.instance.paginatedQuery(
            'Loading next page from cache: $cacheKey',
          );
          final combinedData = List<TData>.from(state.value.data)
            ..addAll(cachedResponse.items);
          state.value = state.value.copyWith(
            data: combinedData,
            loadingState: PaginatedQueryLoadingState.success,
            currentPage: nextPage,
            hasNextPage: cachedResponse.hasNextPage,
          );
          return;
        }
      }

      DAQLogger.instance.paginatedQuery(
        'Loading next page by using the fetcher',
      );
      final result = await fetcher(state.value.parameters, nextPage, pageSize);

      // Cache the result
      if (enableCache) {
        cache.addToCache(cacheKey, result, tags: cacheTags);
      }

      final combinedData = List<TData>.from(state.value.data)
        ..addAll(result.items);
      if (context.mounted) {
        state.value = state.value.copyWith(
          data: combinedData,
          loadingState: PaginatedQueryLoadingState.success,
          currentPage: nextPage,
          hasNextPage: result.hasNextPage,
        );
      }
    } on Object catch (error, stackTrace) {
      DAQLogger.instance.error(
        'Error occurred: $error',
        'DAQ Paginated Query',
        error,
      );

      final transformedError = errorTransformer(error, stackTrace);

      if (context.mounted) {
        state.value = state.value.copyWith(
          loadingState: PaginatedQueryLoadingState.error,
          error: transformedError,
        );
      }
    }
  }

  // Fetch previous page (for bidirectional pagination)
  Future<void> fetchPreviousPage() async {
    if (state.value.currentPage <= 1 ||
        state.value.loadingState == PaginatedQueryLoadingState.loadingMore) {
      return;
    }

    final prevPage = state.value.currentPage - 1;

    if (context.mounted) {
      state.value = state.value.copyWith(
        loadingState: PaginatedQueryLoadingState.loadingMore,
      );
    }

    try {
      final cacheKey = generateCacheKey(state.value.parameters, prevPage);

      // Check cache first
      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedResponse = cache.getValue<DAQPaginatedQueryResponse<TData>>(
          cacheKey,
        );
        if (cachedResponse != null) {
          DAQLogger.instance.paginatedQuery(
            'Loading prev page from cache: $cacheKey',
          );
          if (context.mounted) {
            state.value = state.value.copyWith(
              data: cachedResponse.items,
              loadingState: PaginatedQueryLoadingState.success,
              currentPage: prevPage,
              hasNextPage:
                  true, // Since we went back, there's definitely a next page
            );
          }
          return;
        }
      }

      DAQLogger.instance.paginatedQuery(
        'Loading prev page by using the fetcher',
      );
      final result = await fetcher(state.value.parameters, prevPage, pageSize);

      // Cache the result
      if (enableCache) {
        cache.addToCache(cacheKey, result, tags: cacheTags);
      }

      if (context.mounted) {
        state.value = state.value.copyWith(
          data: result.items,
          loadingState: PaginatedQueryLoadingState.success,
          currentPage: prevPage,
          hasNextPage:
              true, // Since we went back, there's definitely a next page
        );
      }
    } on Object catch (error, stackTrace) {
      DAQLogger.instance.error(
        'Error occurred: $error',
        'DAQ Paginated Query',
        error,
      );

      final transformedError = errorTransformer(error, stackTrace);

      if (context.mounted) {
        state.value = state.value.copyWith(
          loadingState: PaginatedQueryLoadingState.error,
          error: transformedError,
        );
      }
    }
  }

  // Refetch from ground up (clear cache and start fresh)
  Future<void> refetchFromStart({TParams? newParameters}) async {
    DAQLogger.instance.paginatedQuery(
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

  // Auto-fetch on mount
  useEffect(() {
    if (autoFetch && state.value.data.isEmpty && !state.value.isLoading) {
      fetch();
    }
    return null;
  }, [autoFetch]);

  // Subscribe to cache invalidation events
  useInvalidationSub(
    cache: cache,
    keyPattern: '${cachePrefix}_${state.value.parameters.hashCode}_page_*',
    cacheTags: cacheTags,
    logPrefix: 'paginated query',
    onInvalidated: () {
      if (state.value.data.isNotEmpty) {
        refetchFromStart();
      }
    },
  );

  // Subscribe to cache mutation events
  useEffect(() {
    late StreamSubscription mutationSubscription;

    mutationSubscription = cache.mutationStream.listen((event) {
      bool shouldUpdate = false;
      final updatedPages = <int, DAQPaginatedQueryResponse<TData>>{};

      final filterHash = state.value.parameters.hashCode;
      final keyPattern = '${cachePrefix}_${filterHash}_page_';

      for (final mutatedKey in event.mutatedKeys) {
        if (mutatedKey.startsWith(keyPattern)) {
          final pageMatch = RegExp(r'_page_(\d+)$').firstMatch(mutatedKey);
          if (pageMatch != null) {
            final pageNumber = int.tryParse(pageMatch.group(1)!);
            if (pageNumber != null &&
                event.mutatedData.containsKey(mutatedKey)) {
              try {
                final newPageData =
                    event.mutatedData[mutatedKey]
                        as DAQPaginatedQueryResponse<TData>;
                updatedPages[pageNumber] = newPageData;
                shouldUpdate = true;
              } catch (e) {
                DAQLogger.instance.warning(
                  'Failed to cast mutated data for key $mutatedKey: $e',
                  'DAQ Paginated Query',
                );
              }
            }
          }
        }
      }

      if (shouldUpdate && updatedPages.isNotEmpty) {
        DAQLogger.instance.paginatedQuery(
          'Auto-rebuilding paginated query due to cache mutation: $keyPattern',
        );
        // For now, if page 1 was updated, rebuild the entire data
        // TODO: I GUESS HERE WE CAN TAKE ALL OF THE LOADED ITEMS - SPLIT BY PAGE SIZES AND UPDATE ONLY THOSE PAGES THAT WERE
        // ACTUALLY UPDATED - AND THEN MERGE THEM ALL TOGETHER AGAIN AND UPDATE STATE.
        if (updatedPages.containsKey(1)) {
          final firstPageData = updatedPages[1]!;

          // If we only have the first page, use it directly
          if (state.value.currentPage == 1) {
            state.value = state.value.copyWith(
              data: firstPageData.items,
              totalItems: firstPageData.totalItems,
              totalPages: firstPageData.totalPages,
              hasNextPage: firstPageData.hasNextPage,
            );
          } else {
            // If we have multiple pages loaded, we might need to refetch
            // to maintain consistency, but for now just update what we can

            refetchFromStart();
          }
        }
      }
    });

    return mutationSubscription.cancel;
  }, [cache, cachePrefix, state.value.parameters, cacheTags]);

  // Check if can load more
  final canLoadMore =
      state.value.hasNextPage &&
      state.value.loadingState != PaginatedQueryLoadingState.loadingMore;

  return PaginatedQueryController(
    state.value,
    fetch,
    fetchNextPage,
    fetchPreviousPage,
    refetchFromStart,
    updateParameters,
    canLoadMore,
  );
}
