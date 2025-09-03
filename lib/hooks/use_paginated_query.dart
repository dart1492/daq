import 'package:daq/daq.dart';
import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A custom hook that manages paginated data fetching with caching support
///
/// Usage:
/// ```dart
/// final controller = usePaginatedQuery<ItemType, FilterType>(
///   fetcher: (filters, page, pageSize) => fetchItems(filters, page, pageSize),
///   cachePrefix: 'my_feature',
///   initialFilters: MyFilters(),
///   pageSize: 20,
///   enableCache: true,
///   autoFetch: true,
///   cacheTags: ['my_feature'],
/// );
///
/// // Access state and data
/// if (controller.isLoading) {
///   return LoadingSpinner();
/// }
///
/// final items = controller.data;
///
/// // Control pagination
/// controller.fetchNextPage();
/// controller.fetchPreviousPage();
/// controller.refetchFromStart();
///
/// // Filter management
/// controller.updateFilters(newFilters);
///
/// // Cache management
/// controller.clearCache();
/// controller.clearFeatureCache();
/// ```
PaginatedQueryController<TData, TParams, TError>
usePaginatedQuery<TData, TParams, TError>({
  required Future<DAQPaginatedResponse<TData>> Function(
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
  final state = useState<PaginatedState<TData, TParams, TError>>(
    PaginatedState(data: [], parameters: initialParameters),
  );

  final cache = useDAQCache();

  final daqDebugPrint = useDAQDebug();

  // Generate cache key based on cache prefix, filters and page
  String generateCacheKey(TParams? filters, int page) {
    return '${cachePrefix}_${filters.hashCode}_page_$page';
  }

  // Fetch first page (reset pagination)
  Future<void> fetch({TParams? newParameters}) async {
    state.value = state.value.copyWith(
      loadingState: LoadingState.loading,
      parameters: newParameters ?? state.value.parameters,
      currentPage: 1,
    );

    try {
      final cacheKey = generateCacheKey(state.value.parameters, 1);

      // Check cache first
      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedResponse = cache.getValue<DAQPaginatedResponse<TData>>(
          cacheKey,
        );
        if (cachedResponse != null) {
          daqDebugPrint('[DAQ Paginated Query] Loading from cache: $cacheKey');
          state.value = state.value.copyWith(
            data: cachedResponse.items,
            loadingState: LoadingState.success,
            totalPages: cachedResponse.totalPages,
            totalItems: cachedResponse.totalItems,
            hasNextPage: cachedResponse.hasNextPage,
          );
          return;
        }
      }

      daqDebugPrint('[DAQ Paginated Query] Fetching from API: $cacheKey');
      final result = await fetcher(state.value.parameters, 1, pageSize);

      // Cache the result
      if (enableCache) {
        cache.addToCache(cacheKey, result, tags: cacheTags);
      }

      state.value = state.value.copyWith(
        data: result.items,
        loadingState: LoadingState.success,
        totalPages: result.totalPages,
        totalItems: result.totalItems,
        hasNextPage: result.hasNextPage,
      );
    } on Object catch (error, stackTrace) {
      daqDebugPrint('[DAQ Paginated Query] Error occurred: $error');

      final transformedError = errorTransformer(error, stackTrace);

      state.value = state.value.copyWith(
        loadingState: LoadingState.error,
        error: transformedError,
      );
    }
  }

  // Fetch next page (append to existing data)
  Future<void> fetchNextPage() async {
    if (!state.value.hasNextPage ||
        state.value.loadingState == LoadingState.loadingMore) {
      return;
    }

    final nextPage = state.value.currentPage + 1;
    state.value = state.value.copyWith(loadingState: LoadingState.loadingMore);

    try {
      final cacheKey = generateCacheKey(state.value.parameters, nextPage);

      // Check cache first
      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedResponse = cache.getValue<DAQPaginatedResponse<TData>>(
          cacheKey,
        );
        if (cachedResponse != null) {
          daqDebugPrint(
            '[DAQ Paginated Query] Loading next page from cache: $cacheKey',
          );
          final combinedData = List<TData>.from(state.value.data)
            ..addAll(cachedResponse.items);
          state.value = state.value.copyWith(
            data: combinedData,
            loadingState: LoadingState.success,
            currentPage: nextPage,
            hasNextPage: cachedResponse.hasNextPage,
          );
          return;
        }
      }

      daqDebugPrint(
        '[DAQ Paginated Query] Loading next page by using the fetcher',
      );
      final result = await fetcher(state.value.parameters, nextPage, pageSize);

      // Cache the result
      if (enableCache) {
        cache.addToCache(cacheKey, result, tags: cacheTags);
      }

      final combinedData = List<TData>.from(state.value.data)
        ..addAll(result.items);

      state.value = state.value.copyWith(
        data: combinedData,
        loadingState: LoadingState.success,
        currentPage: nextPage,
        hasNextPage: result.hasNextPage,
      );
    } on Object catch (error, stackTrace) {
      daqDebugPrint('[DAQ Paginated Query] Error occurred: $error');

      final transformedError = errorTransformer(error, stackTrace);

      state.value = state.value.copyWith(
        loadingState: LoadingState.error,
        error: transformedError,
      );
    }
  }

  // Fetch previous page (for bidirectional pagination)
  Future<void> fetchPreviousPage() async {
    if (state.value.currentPage <= 1 ||
        state.value.loadingState == LoadingState.loadingMore) {
      return;
    }

    final prevPage = state.value.currentPage - 1;
    state.value = state.value.copyWith(loadingState: LoadingState.loadingMore);

    try {
      final cacheKey = generateCacheKey(state.value.parameters, prevPage);

      // Check cache first
      if (enableCache && cache.hasKey(cacheKey)) {
        final cachedResponse = cache.getValue<DAQPaginatedResponse<TData>>(
          cacheKey,
        );
        if (cachedResponse != null) {
          daqDebugPrint(
            '[DAQ Paginated Query] Loading prev page from cache: $cacheKey',
          );
          state.value = state.value.copyWith(
            data: cachedResponse.items,
            loadingState: LoadingState.success,
            currentPage: prevPage,
            hasNextPage:
                true, // Since we went back, there's definitely a next page
          );
          return;
        }
      }

      daqDebugPrint(
        '[DAQ Paginated Query] Loading prev page by using the fetcher',
      );
      final result = await fetcher(state.value.parameters, prevPage, pageSize);

      // Cache the result
      if (enableCache) {
        cache.addToCache(cacheKey, result, tags: cacheTags);
      }

      state.value = state.value.copyWith(
        data: result.items,
        loadingState: LoadingState.success,
        currentPage: prevPage,
        hasNextPage: true, // Since we went back, there's definitely a next page
      );
    } on Object catch (error, stackTrace) {
      daqDebugPrint('[DAQ Paginated Query] Error occurred: $error');

      final transformedError = errorTransformer(error, stackTrace);

      state.value = state.value.copyWith(
        loadingState: LoadingState.error,
        error: transformedError,
      );
    }
  }

  // Refetch from ground up (clear cache and start fresh)
  Future<void> refetchFromStart({TParams? newParameters}) async {
    daqDebugPrint(
      '[DAQ Paginated Query] Refetching the whole list form the start',
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
  useEffect(() {
    late StreamSubscription invalidationSubscription;

    invalidationSubscription = cache.invalidationStream.listen((event) {
      // Check if any of our cache keys were invalidated
      bool shouldRefetch = false;

      // Check all pages for this filter set
      final filterHash = state.value.parameters.hashCode;
      final keyPattern = '${cachePrefix}_${filterHash}_page_';

      // Direct key match
      for (final invalidatedKey in event.invalidatedKeys) {
        if (invalidatedKey.startsWith(keyPattern)) {
          shouldRefetch = true;
          break;
        }
      }

      // Pattern match
      if (!shouldRefetch && event.pattern != null) {
        final regex = RegExp(event.pattern!.replaceAll('*', '.*'));
        if (regex.hasMatch('${cachePrefix}_${filterHash}_page_1')) {
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
      if (shouldRefetch && state.value.data.isNotEmpty) {
        daqDebugPrint(
          '[DAQ Paginated Query] Auto-refetching paginated query due to cache invalidation: $keyPattern',
        );

        refetchFromStart();
      }
    });

    return invalidationSubscription.cancel;
  }, [cache, cachePrefix, state.value.parameters, cacheTags]);

  // Subscribe to cache mutation events
  useEffect(() {
    late StreamSubscription mutationSubscription;

    mutationSubscription = cache.mutationStream.listen((event) {
      bool shouldUpdate = false;
      final updatedPages = <int, DAQPaginatedResponse<TData>>{};

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
                        as DAQPaginatedResponse<TData>;
                updatedPages[pageNumber] = newPageData;
                shouldUpdate = true;
              } catch (e) {
                daqDebugPrint(
                  '[DAQ Paginated Query] ⚠️ Failed to cast mutated data for key $mutatedKey: $e',
                );
              }
            }
          }
        }
      }

      if (shouldUpdate && updatedPages.isNotEmpty) {
        daqDebugPrint(
          '[DAQ Paginated Query] Auto-rebuilding paginated query due to cache mutation: $keyPattern',
        );
        // For now, if page 1 was updated, rebuild the entire data
        // More sophisticated merging could be implemented later
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
      state.value.loadingState != LoadingState.loadingMore;

  return PaginatedQueryController._(
    state.value,
    fetch,
    fetchNextPage,
    fetchPreviousPage,
    refetchFromStart,
    updateParameters,

    canLoadMore,
  );
}

/// Controller wrapper that provides a clean API for list management
class PaginatedQueryController<TData, TParams, TError> {
  PaginatedQueryController._(
    this.state,
    this._fetch,
    this._fetchNextPage,
    this._fetchPreviousPage,
    this._refetchFromStart,
    this._updateParameters,
    this._canLoadMore,
  );

  final PaginatedState<TData, TParams, TError> state;
  final Future<void> Function({TParams? newParameters}) _fetch;
  final Future<void> Function() _fetchNextPage;
  final Future<void> Function() _fetchPreviousPage;
  final Future<void> Function({TParams? newParameters}) _refetchFromStart;
  final void Function(TParams newFilters) _updateParameters;
  final bool _canLoadMore;

  // Getters for common state checks
  bool get isLoading => state.isLoading;
  bool get isLoadingMore => state.isLoadingMore;
  bool get isSuccess => state.isSuccess;
  bool get hasError => state.hasError;
  bool get isEmpty => state.isEmpty;
  bool get isNotEmpty => state.isNotEmpty;
  bool get canLoadMore => _canLoadMore;

  List<TData> get data => state.data;
  TParams? get filters => state.parameters;
  TError? get error => state.error;
  int get currentPage => state.currentPage;
  int get totalPages => state.totalPages;
  int get totalItems => state.totalItems;
  bool get hasNextPage => state.hasNextPage;

  // Actions
  Future<void> fetch({TParams? newParameters}) =>
      _fetch(newParameters: newParameters);

  Future<void> fetchNextPage() => _fetchNextPage();

  Future<void> fetchPreviousPage() => _fetchPreviousPage();

  Future<void> refetchFromStart({TParams? newFilters}) =>
      _refetchFromStart(newParameters: newFilters);

  void updateParameters(TParams newParameters) =>
      _updateParameters(newParameters);
}

enum LoadingState { initial, loading, loadingMore, success, error }

class PaginatedState<TData, TParams, TError> {
  final List<TData> data;
  final TParams parameters;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final LoadingState loadingState;
  final TError? error;

  const PaginatedState({
    this.data = const [],
    required this.parameters,
    this.currentPage = 1,
    this.totalPages = 0,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.loadingState = LoadingState.initial,
    this.error,
  });

  PaginatedState<TData, TParams, TError> copyWith({
    List<TData>? data,
    TParams? parameters,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    LoadingState? loadingState,
    TError? error,
  }) {
    return PaginatedState<TData, TParams, TError>(
      data: data ?? this.data,
      parameters: parameters ?? this.parameters,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
    );
  }

  // Convenience getters
  bool get isLoading => loadingState == LoadingState.loading;
  bool get isLoadingMore => loadingState == LoadingState.loadingMore;
  bool get isSuccess => loadingState == LoadingState.success;
  bool get hasError => loadingState == LoadingState.error;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
  int get itemCount => data.length;
}

class DAQPaginatedResponse<T> {
  DAQPaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
  });
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
}
