import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:daq/utils/daq_cache/daq_cache.dart';
import 'package:daq/utils/daq_logger.dart';

/// Add TTL (Time To Live) subscription to periodically check cache entries
/// and trigger refetch when they expire
void useTTLSub({
  required DAQCache cache,
  required List<String> cacheKeys,
  required Duration timeToLive,
  required VoidCallback onExpired,
  Duration checkInterval = const Duration(minutes: 1),
  String? logPrefix,
}) {
  useEffect(() {
    late Timer ttlTimer;

    // Function to check if any cache entries have expired
    void checkTTL() {
      final now = DateTime.now();
      bool hasExpiredEntries = false;

      for (final cacheKey in cacheKeys) {
        if (cache.hasKey(cacheKey)) {
          final cacheEntry = cache.getEntry(cacheKey);
          if (cacheEntry != null) {
            final timeSinceWrite = now.difference(cacheEntry.lastWriteTime);

            if (timeSinceWrite >= timeToLive) {
              hasExpiredEntries = true;

              final logMessage = logPrefix != null
                  ? 'TTL expired for $logPrefix cache key: $cacheKey'
                  : 'TTL expired for cache key: $cacheKey';

              DAQLogger.instance.query(logMessage);
              break;
            }
          }
        }
      }

      // Trigger refetch if any entries have expired
      if (hasExpiredEntries) {
        final logMessage = logPrefix != null
            ? 'Auto-refetching $logPrefix due to TTL expiration'
            : 'Auto-refetching due to TTL expiration';

        DAQLogger.instance.info(logMessage, 'DAQ TTL Sub');
        onExpired();
      }
    }

    // Start the periodic TTL check timer
    ttlTimer = Timer.periodic(checkInterval, (_) {
      checkTTL();
    });

    return ttlTimer.cancel;
  }, [cache, cacheKeys, timeToLive, checkInterval]);
}
