/// Handles request deduplication to avoid duplicate requests for the same key
///
/// //TODO: THINK ABOUT THE FUTURES THAT ARE STILL RUNNING WHEN WE REBUILD THE CACHE ISNTANCE - NEED SOME WAY TO CANCEL THE FUTURE
class RequestDeduplicator {
  // to avoid request duplication on one key
  final Map<String, Future<dynamic>> _inflightRequests = {};

  /// Check if there's an inflight request for this key
  bool hasInflightRequest(String key) {
    return _inflightRequests.containsKey(key);
  }

  /// Get the inflight request for this key if it exists
  Future<T>? getInflightRequest<T>(String key) {
    final future = _inflightRequests[key];
    if (future is Future<T>) {
      return future;
    }
    return null;
  }

  /// Register a request by its key. If it is already running - return the existing instance
  Future<T> executeWithDeduplication<T>(
    String key,
    Future<T> Function() requestFn,
  ) async {
    // Check if request is already inflight
    if (_inflightRequests.containsKey(key)) {
      final existingRequest = _inflightRequests[key];
      if (existingRequest is Future<T>) {
        return existingRequest;
      }
    }

    // Start new request and track it
    final requestFuture = requestFn();
    _inflightRequests[key] = requestFuture;

    try {
      final result = await requestFuture;
      return result;
    } finally {
      // Remove from inflight requests when done (success or failure)
      _inflightRequests.remove(key);
    }
  }

  /// Remove inflight request for a key
  void removeInflightRequest(String key) {
    _inflightRequests.remove(key);
  }

  /// Clear all inflight requests
  void clearAllInflightRequests() {
    _inflightRequests.clear();
  }

  /// Get all inflight request keys
  List<String> get inflightKeys => _inflightRequests.keys.toList();
}
