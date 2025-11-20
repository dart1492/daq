class DAQUtilFunctions {
  /// pass the cache entry's lastWrite parameter and the expected ttl to get if the entry should be re-fetched or no.
  static bool checkIsAlive({required DateTime lastWrite, Duration? ttl}) {
    if (ttl == null) {
      return true;
    }
    DateTime now = DateTime.now();

    if (now.difference(lastWrite) < ttl) {
      return true;
    } else {
      return false;
    }
  }
}
