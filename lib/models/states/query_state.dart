/// Represents the state of a simple query
class QueryState<TData, TError> {
  const QueryState({required this.status, this.data, this.error});
  const QueryState._({required this.status, this.data, this.error});

  factory QueryState.initial() =>
      const QueryState._(status: QueryLoadingState.idle);

  factory QueryState.error(TError error) =>
      QueryState._(status: QueryLoadingState.error, error: error, data: null);

  factory QueryState.success(TData data) =>
      QueryState._(status: QueryLoadingState.success, error: null, data: data);

  final QueryLoadingState status;
  final TData? data;
  final TError? error;

  QueryState<TData, TError> copyWith({
    QueryLoadingState? status,
    TData? data,
    TError? error,
  }) {
    return QueryState._(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

/// Enum representing the status of a simple query
enum QueryLoadingState { idle, loading, success, error }

/// Extension to provide convenient methods for query status
extension QueryStatusX on QueryLoadingState {
  bool get isIdle => this == QueryLoadingState.idle;
  bool get isLoading => this == QueryLoadingState.loading;
  bool get isSuccess => this == QueryLoadingState.success;
  bool get isError => this == QueryLoadingState.error;
}
