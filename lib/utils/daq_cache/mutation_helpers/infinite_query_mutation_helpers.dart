import 'package:daq/models/index.dart';
import 'package:daq/utils/daq_cache/index.dart';

/// To help with mutation items for infinite queries.
extension InfiniteQueryMutationHelpers on DAQCache {
  /// Find by the [matcher] and replace with the [updater] in all query cache results, that start with the
  /// [keyPrefix], and are of type [DAQInfiniteQueryResponse]
  void updateItemInInfiniteQuery<T>({
    required String keyPrefix,
    required Function(T) matcher,
    required Function(T) updater,
  }) {
    final mutatedKeys = <String>[];
    final mutatedData = <String, dynamic>{};

    final allKeys = getKeysByPattern('${keyPrefix}_*');

    for (String key in allKeys) {
      final singleResponse = getValue(key);

      if (singleResponse is DAQInfiniteQueryResponse<T>?) {
        if (singleResponse == null) continue;

        final updatedItems = singleResponse.items.map<T>((item) {
          if (matcher(item)) {
            return updater(item);
          }
          return item;
        }).toList();

        final updatedResponse = singleResponse.copyWith(items: updatedItems);
        addToCache(key, updatedResponse);
        mutatedKeys.add(key);
        mutatedData[key] = updatedResponse;
      }
    }

    if (mutatedKeys.isNotEmpty) {
      updateCacheBatch(mutatedKeys, mutatedData);
    }
  }
}
