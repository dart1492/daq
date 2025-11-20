import 'package:daq/models/states/index.dart';

/// Controller for simple queries
class QueryController<TData, TParams, TError> {
  const QueryController({
    required this.state,
    required this.fetch,
    required this.refetch,
    required this.updateParameters,
  });

  final QueryState<TData, TError, TParams> state;
  final Future<void> Function({TParams? newParameters}) fetch;
  final Future<void> Function() refetch;
  final void Function(TParams newParameters) updateParameters;

  // Getters for common state checks
  bool get isLoading => state.status == QueryLoadingState.loading;
  bool get isSuccess => state.status == QueryLoadingState.success;
  bool get hasError => state.status == QueryLoadingState.error;
  bool get isIdle => state.status == QueryLoadingState.idle;

  TData? get data => state.data;
  TParams? get params => state.params;
  TError? get error => state.error;
  QueryLoadingState get status => state.status;

  // Actions
  Future<void> fetchData({TParams? newParameters}) =>
      fetch(newParameters: newParameters);

  Future<void> refetchData() => refetch();

  void updateQueryVariables(TParams newVariables) =>
      updateParameters(newVariables);
}
