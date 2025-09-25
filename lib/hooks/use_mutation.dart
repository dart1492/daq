import 'package:daq/daq.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Use mutation hook
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
  final context = useContext();

  final daqCache = useDAQCache();

  final state = useState(MutationState<TData, TError>.initial());

  final mutate = useCallback((TVariables variables) async {
    try {
      onMutating?.call(variables);

      if (context.mounted) {
        state.value = state.value.copyWith(
          status: MutationLoadingState.loading,
          error: null,
        );
      }

      DAQLogger.instance.mutation(
        'Starting mutation with variables: $variables',
      );

      late TData result;

      if (timeout != null) {
        result = await mutationFn(variables).timeout(timeout);
      } else {
        result = await mutationFn(variables);
      }

      if (context.mounted) {
        state.value = MutationState.success(result);
      }

      DAQLogger.instance.success(
        'Mutation function completed successfully vType: ${variables.runtimeType}',
        'DAQ Mutation',
      );

      // Invalidate cache if needed (alternative to cache updates)
      if (invalidatePatterns != null) {
        DAQLogger.instance.mutation(
          'Invalidating cache by patterns: $invalidatePatterns',
        );
        for (final pattern in invalidatePatterns) {
          daqCache.invalidateByPattern(pattern);
        }
      }

      if (invalidateTags != null) {
        DAQLogger.instance.mutation(
          'Invalidating cache by tags: $invalidateTags',
        );
        daqCache.invalidateByTags(invalidateTags);
      }

      if (invalidateKeys != null) {
        DAQLogger.instance.mutation(
          'Invalidating cache by keys: $invalidateKeys',
        );
        daqCache.invalidateKeys(invalidateKeys);
      }

      if (context.mounted) {
        onSuccess?.call(result, variables, daqCache);
      }
    } catch (error, stackTrace) {
      final errorTransformed = errorTransformer(error, stackTrace);

      DAQLogger.instance.error('Error occurred: $error', 'DAQ Mutation', error);

      if (context.mounted) {
        state.value = MutationState.error(errorTransformed);

        onError?.call(errorTransformed, variables, daqCache);
      }
    } finally {
      if (context.mounted) {
        onSettled?.call();
      }
    }
  }, [mutationFn, onSuccess, onError, onSettled, onMutating, timeout]);

  final reset = useCallback(() {
    DAQLogger.instance.info(
      'Resetting mutation state to initial',
      'DAQ Mutation',
    );

    state.value = MutationState<TData, TError>.initial();
  }, []);

  return MutationController(state: state.value, mutate: mutate, reset: reset);
}
