import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:daq/utils/daq_cache/daq_cache.dart';
import 'package:daq/utils/daq_logger.dart';

/// Add mutation subscription to the query hook
void useMutationSub<TData>({
  required DAQCache cache,
  List<String>? cacheKeys,
  String? keyPattern,
  List<String>? cacheTags,
  required void Function(TData mutatedData) onMutated,
  String? logPrefix,
}) {
  useEffect(() {
    late StreamSubscription mutationSubscription;

    mutationSubscription = cache.mutationStream.listen((event) {
      bool shouldUpdate = false;
      dynamic newData;

      // Direct key match
      if (cacheKeys != null) {
        for (final cacheKey in cacheKeys) {
          if (event.mutatedKeys.contains(cacheKey)) {
            shouldUpdate = true;
            newData = event.mutatedData[cacheKey];
            break;
          }
        }
      }

      // Pattern match
      if (!shouldUpdate && event.pattern != null) {
        final regex = RegExp(event.pattern!.replaceAll('*', '.*'));
        if (cacheKeys != null) {
          for (final cacheKey in cacheKeys) {
            if (regex.hasMatch(cacheKey)) {
              // Find the mutated data for this key
              for (final key in event.mutatedKeys) {
                if (key == cacheKey) {
                  shouldUpdate = true;
                  newData = event.mutatedData[key];
                  break;
                }
              }
              if (shouldUpdate) break;
            }
          }
        }
        if (!shouldUpdate && keyPattern != null) {
          final keyRegex = RegExp(keyPattern.replaceAll('*', '.*'));
          for (final mutatedKey in event.mutatedKeys) {
            if (keyRegex.hasMatch(mutatedKey)) {
              shouldUpdate = true;
              newData = event.mutatedData[mutatedKey];
              break;
            }
          }
        }
      }

      // Tag match
      if (!shouldUpdate && event.tags != null && cacheTags != null) {
        final eventTagsSet = event.tags!.toSet();
        final cacheTagsSet = cacheTags.toSet();
        if (eventTagsSet.intersection(cacheTagsSet).isNotEmpty) {
          // Check if our specific keys were mutated
          if (cacheKeys != null) {
            for (final cacheKey in cacheKeys) {
              if (event.mutatedKeys.contains(cacheKey)) {
                shouldUpdate = true;
                newData = event.mutatedData[cacheKey];
                break;
              }
            }
          }
        }
      }

      // Trigger callback if mutated
      if (shouldUpdate && newData != null) {
        final logMessage = logPrefix != null
            ? 'Auto-updating $logPrefix due to cache mutation'
            : 'Auto-updating due to cache mutation';

        DAQLogger.instance.info(logMessage, 'DAQ Mutation Sub');

        try {
          onMutated(newData as TData);
        } catch (e) {
          DAQLogger.instance.warning(
            'Failed to cast mutated data: $e',
            'DAQ Mutation Sub',
          );
        }
      }
    });

    return mutationSubscription.cancel;
  }, [cache, cacheKeys, keyPattern, cacheTags]);
}
