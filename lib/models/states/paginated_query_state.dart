enum PaginatedQueryLoadingState {
  initial,
  loading,
  loadingMore,
  success,
  error,
}

class PaginatedQueryState<TData, TParams, TError> {
  final List<TData> data;
  final TParams parameters;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final PaginatedQueryLoadingState loadingState;
  final TError? error;

  const PaginatedQueryState({
    this.data = const [],
    required this.parameters,
    this.currentPage = 1,
    this.totalPages = 0,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.loadingState = PaginatedQueryLoadingState.initial,
    this.error,
  });

  PaginatedQueryState<TData, TParams, TError> copyWith({
    List<TData>? data,
    TParams? parameters,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    PaginatedQueryLoadingState? loadingState,
    TError? error,
  }) {
    return PaginatedQueryState<TData, TParams, TError>(
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
  bool get isLoading => loadingState == PaginatedQueryLoadingState.loading;
  bool get isLoadingMore =>
      loadingState == PaginatedQueryLoadingState.loadingMore;
  bool get isSuccess => loadingState == PaginatedQueryLoadingState.success;
  bool get hasError => loadingState == PaginatedQueryLoadingState.error;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
  int get itemCount => data.length;
}

class DAQPaginatedQueryResponse<T> {
  DAQPaginatedQueryResponse({
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
