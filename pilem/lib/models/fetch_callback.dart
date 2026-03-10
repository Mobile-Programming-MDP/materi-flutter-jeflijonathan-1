class FetchCallback {
  final Function(dynamic data) onSuccess;
  final Function(dynamic error) onError;
  final Function() onFullfilled;

  const FetchCallback({
    required this.onSuccess,
    required this.onError,
    required this.onFullfilled,
  });
}
