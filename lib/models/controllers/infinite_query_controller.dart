import 'package:daq/models/states/infinite_query_state.dart';

class InfiniteQueryController<TData, TParams, TError> {
  InfiniteQueryController(
    this.state,
    this._fetch,
    this._fetchNextPage,
    this._refetchFromStart,
    this._updateParameters,
    this._canLoadMore,
  );

  final InfiniteQueryState<TData, TParams, TError> state;
  final Future<void> Function({TParams? newParameters}) _fetch;
  final Future<void> Function() _fetchNextPage;
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

  Future<void> refetchFromStart({TParams? newFilters}) =>
      _refetchFromStart(newParameters: newFilters);

  void updateParameters(TParams newParameters) =>
      _updateParameters(newParameters);
}
