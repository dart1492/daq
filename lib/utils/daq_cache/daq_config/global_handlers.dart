// ignore_for_file: public_member_api_docs, sort_constructors_first
/// Allows to get all successes and error events from all of the queries/infiniteQueries/mutations
class GlobalDAQHandlers {
  Function(GlobalSuccessEvent event)? onSuccess;
  Function(GlobalErrorEvent event)? onError;
  GlobalDAQHandlers({this.onSuccess, this.onError});
}

enum GlobalEvenTypes { query, infiniteQuery, mutation }

class GlobalSuccessEvent {
  GlobalEvenTypes type;
  dynamic data;
  GlobalSuccessEvent({required this.type, this.data});
}

class GlobalErrorEvent {
  GlobalEvenTypes type;
  dynamic data;
  GlobalErrorEvent({required this.type, this.data});
}
