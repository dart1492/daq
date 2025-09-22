import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:daq/utils/async_cache/daq_cache.dart';
import 'package:daq/utils/daq_logger.dart';

/// A hook that subscribes to cache invalidation events and triggers a callback when relevant keys are invalidated
///
/// This hook handles three types of invalidation matching:
/// 1. Direct key matching - exact cache key matches
/// 2. Pattern matching - regex pattern matching against cache keys
/// 3. Tag matching - matching based on cache tags
///
/// Usage:
/// ```dart
/// useInvalidationSub(
///   cache: cache,
///   cacheKeys: ['my_key_1', 'my_key_2'],
///   keyPattern: 'my_prefix_*',
///   cacheTags: ['my_feature'],
///   onInvalidated: () {
///     // Handle invalidation - e.g., refetch data
///     refetch();
///   },
/// );
/// ```
void useInvalidationSub({
  required DAQCache cache,
  List<String>? cacheKeys,
  String? keyPattern,
  List<String>? cacheTags,
  required VoidCallback onInvalidated,
  String? logPrefix,
}) {
  useEffect(() {
    late StreamSubscription invalidationSubscription;

    invalidationSubscription = cache.invalidationStream.listen((event) {
      bool shouldRefetch = false;

      // Direct key match
      if (cacheKeys != null) {
        for (final cacheKey in cacheKeys) {
          if (event.invalidatedKeys.contains(cacheKey)) {
            shouldRefetch = true;
            break;
          }
        }
      }

      // Pattern match
      if (!shouldRefetch && event.pattern != null) {
        final regex = RegExp(event.pattern!.replaceAll('*', '.*'));
        if (cacheKeys != null) {
          for (final cacheKey in cacheKeys) {
            if (regex.hasMatch(cacheKey)) {
              shouldRefetch = true;
              break;
            }
          }
        }
        if (!shouldRefetch && keyPattern != null) {
          final keyRegex = RegExp(keyPattern.replaceAll('*', '.*'));
          for (final invalidatedKey in event.invalidatedKeys) {
            if (keyRegex.hasMatch(invalidatedKey)) {
              shouldRefetch = true;
              break;
            }
          }
        }
      }

      // Tag match
      if (!shouldRefetch && event.tags != null && cacheTags != null) {
        final eventTagsSet = event.tags!.toSet();
        final cacheTagsSet = cacheTags.toSet();
        if (eventTagsSet.intersection(cacheTagsSet).isNotEmpty) {
          shouldRefetch = true;
        }
      }

      // Trigger callback if invalidated
      if (shouldRefetch) {
        final logMessage = logPrefix != null
            ? 'Auto-refetching $logPrefix due to cache invalidation'
            : 'Auto-refetching due to cache invalidation';

        DAQLogger.instance.info(logMessage, 'DAQ Invalidation Sub');
        onInvalidated();
      }
    });

    return invalidationSubscription.cancel;
  }, [cache, cacheKeys, keyPattern, cacheTags]);
}
