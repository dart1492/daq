import 'package:daq/models/states/mutation_state.dart';
import 'package:flutter/foundation.dart';

/// Controller that provides access to mutation state and actions
class MutationController<TData, TVariables, TError> {
  const MutationController({
    required this.state,
    required this.mutate,
    required this.reset,
  });

  final MutationState<TData, TError> state;
  final Future<void> Function(TVariables variables) mutate;
  final VoidCallback reset;

  bool get isIdle => state.status == MutationLoadingState.idle;
  bool get isLoading => state.status == MutationLoadingState.loading;
  bool get isSuccess => state.status == MutationLoadingState.success;
  bool get isError => state.status == MutationLoadingState.error;

  TData? get data => state.data;
  Object? get error => state.error;
  MutationLoadingState get status => state.status;
}
