import 'package:daq/models/states/paginated_query_state.dart';

/// Controller wrapper that provides a clean API for list management
class PaginatedQueryController<TData, TParams, TError> {
  PaginatedQueryController(
    this.state,
    this._fetch,
    this._fetchNextPage,
    this._fetchPreviousPage,
    this._refetchFromStart,
    this._updateParameters,
    this._canLoadMore,
  );

  final PaginatedQueryState<TData, TParams, TError> state;
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
