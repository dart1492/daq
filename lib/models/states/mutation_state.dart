/// Mutation state class
class MutationState<TData, TError> {
  const MutationState._({required this.status, this.data, this.error});

  factory MutationState.initial() =>
      const MutationState._(status: MutationLoadingState.idle);

  factory MutationState.success(TData data) =>
      MutationState._(status: MutationLoadingState.success, data: data);

  factory MutationState.error(TError error) =>
      MutationState._(status: MutationLoadingState.error, error: error);

  final MutationLoadingState status;
  final TData? data;
  final TError? error;

  MutationState<TData, TError> copyWith({
    MutationLoadingState? status,
    TData? data,
    TError? error,
  }) {
    return MutationState._(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

/// Enum representing the status of a mutation
enum MutationLoadingState { idle, loading, success, error }

/// Extension to provide convenient methods for mutation status
extension MutationStatusX on MutationLoadingState {
  bool get isIdle => this == MutationLoadingState.idle;
  bool get isLoading => this == MutationLoadingState.loading;
  bool get isSuccess => this == MutationLoadingState.success;
  bool get isError => this == MutationLoadingState.error;
}
