/// Represents the state of a simple query
class QueryState<TData, TError, TParams> {
  const QueryState({
    required this.status,
    this.data,
    this.error,
    required this.params,
  });
  const QueryState._({
    required this.status,
    this.data,
    this.error,
    required this.params,
  });

  factory QueryState.initial(TParams params) =>
      QueryState._(status: QueryLoadingState.idle, params: params);

  factory QueryState.error(TError error, TParams params) => QueryState._(
    status: QueryLoadingState.error,
    error: error,
    data: null,
    params: params,
  );

  factory QueryState.success(TData data, TParams params) => QueryState._(
    status: QueryLoadingState.success,
    error: null,
    data: data,
    params: params,
  );

  final QueryLoadingState status;
  final TData? data;
  final TParams params;
  final TError? error;

  QueryState<TData, TError, TParams> copyWith({
    QueryLoadingState? status,
    TData? data,
    TError? error,
    TParams? params,
  }) {
    return QueryState._(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      params: params ?? this.params,
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
