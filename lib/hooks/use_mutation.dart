import 'dart:math';

import 'package:daq/darts_async_query.dart';
import 'package:daq/utils/async_cache/index.dart';
import 'package:daq/hooks/use_daq_debug.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A custom hook that manages mutation state and provides a clean API for POST, PUT, DELETE operations
///
/// Usage:
/// ```dart
/// final createUser = useMutation<User, CreateUserRequest, MyAppError>(
///   mutationFn: (request) => api.createUser(request),
///   errorTransformer: (error, stackTrace) => MyAppError()
///   onMutating: (request) {
///     // Called when mutation starts - useful for showing loading states
///     showLoadingIndicator();
///   },
///   onSuccess: (user, request) {
///     print('User created: ${user.id}');
///     // Optionally invalidate related caches
///     listController.refetchFromStart();
///   },
///   onError: (error, request) {
///     showSnackBar('Failed to create user: $error');
///   },
/// );
///
/// // Trigger mutation
/// createUser.mutate(CreateUserRequest(name: 'John'));
///
/// // Check state
/// if (createUser.isLoading) { ... }
/// if (createUser.isSuccess) { ... }
/// ```
MutationController<TData, TVariables, TError>
useMutation<TData, TVariables, TError>({
  required Future<TData> Function(TVariables variables) mutationFn,

  void Function(TData data, TVariables variables, DAQCache cacheInstance)?
  onSuccess,

  void Function(TError error, TVariables variables, DAQCache cacheInstance)?
  onError,

  void Function()? onSettled,

  void Function(TVariables variables)? onMutating,

  required TError Function(Object error, StackTrace stackTrace)
  errorTransformer,

  Duration? timeout,

  List<String>? invalidatePatterns,
  List<String>? invalidateTags,
  List<String>? invalidateKeys,
}) {
  final daqCache = useDAQCache();
  final daqDebugPrint = useDAQDebug();

  final state = useState(MutationState<TData, TError>.initial());

  final mutate = useCallback((TVariables variables) async {
    try {
      onMutating?.call(variables);

      state.value = state.value.copyWith(
        status: MutationStatus.loading,
        error: null,
      );

      daqDebugPrint(
        '[DAQ Mutation] Starting mutation with variables: $variables',
      );

      late TData result;

      if (timeout != null) {
        result = await mutationFn(variables).timeout(timeout);
      } else {
        result = await mutationFn(variables);
      }

      state.value = MutationState.success(result);

      daqDebugPrint('[DAQ Mutation] Mutation function completed successfully');

      // Handle cache after successful mutation
      final cache = daqCache;

      // Invalidate cache if needed (alternative to cache updates)
      if (invalidatePatterns != null) {
        daqDebugPrint(
          '[DAQ Mutation] Invalidating cache by patterns: $invalidatePatterns',
        );
        for (final pattern in invalidatePatterns) {
          cache.invalidateByPattern(pattern);
        }
      }

      if (invalidateTags != null) {
        daqDebugPrint(
          '[DAQ Mutation] Invalidating cache by tags: $invalidateTags',
        );
        cache.invalidateByTags(invalidateTags);
      }

      if (invalidateKeys != null) {
        daqDebugPrint(
          '[DAQ Mutation] Invalidating cache by keys: $invalidateKeys',
        );
        cache.invalidateKeys(invalidateKeys);
      }

      onSuccess?.call(result, variables, daqCache);
    } catch (error, stackTrace) {
      final errorTransformed = errorTransformer(error, stackTrace);

      daqDebugPrint('[DAQ Mutation] Error occurred: $error');

      daqDebugPrint(
        '[DAQ Mutation] Error Stack trace: $stackTrace',
      ); //TODO: STACK TRACE - should I display it fully?

      state.value = MutationState.error(errorTransformed);

      onError?.call(errorTransformed, variables, daqCache);
    } finally {
      onSettled?.call();

      daqDebugPrint(
        '[DAQ Mutation] onSettled callback executed, final status: ${state.value.status}',
      );
    }
  }, [mutationFn, onSuccess, onError, onSettled, onMutating, timeout]);

  final reset = useCallback(() {
    daqDebugPrint('[DAQ Mutation] Resetting mutation state to initial');

    state.value = MutationState<TData, TError>.initial();
  }, []);

  return MutationController._(state: state.value, mutate: mutate, reset: reset);
}

/// Controller that provides access to mutation state and actions
class MutationController<TData, TVariables, TError> {
  const MutationController._({
    required this.state,
    required this.mutate,
    required this.reset,
  });

  final MutationState<TData, TError> state;
  final Future<void> Function(TVariables variables) mutate;
  final VoidCallback reset;

  bool get isIdle => state.status == MutationStatus.idle;
  bool get isLoading => state.status == MutationStatus.loading;
  bool get isSuccess => state.status == MutationStatus.success;
  bool get isError => state.status == MutationStatus.error;

  TData? get data => state.data;
  Object? get error => state.error;
  MutationStatus get status => state.status;
}

/// Mutation state class
class MutationState<TData, TError> {
  const MutationState._({required this.status, this.data, this.error});

  factory MutationState.initial() =>
      const MutationState._(status: MutationStatus.idle);

  factory MutationState.success(TData data) =>
      MutationState._(status: MutationStatus.success, data: data);

  factory MutationState.error(TError error) =>
      MutationState._(status: MutationStatus.error, error: error);

  final MutationStatus status;
  final TData? data;
  final TError? error;

  MutationState<TData, TError> copyWith({
    MutationStatus? status,
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
enum MutationStatus { idle, loading, success, error }

/// Extension to provide convenient methods for mutation status
extension MutationStatusX on MutationStatus {
  bool get isIdle => this == MutationStatus.idle;
  bool get isLoading => this == MutationStatus.loading;
  bool get isSuccess => this == MutationStatus.success;
  bool get isError => this == MutationStatus.error;
}
