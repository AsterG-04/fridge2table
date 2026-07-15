class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  const SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });

  factory SyncResult.failure(String message) =>
      SyncResult(success: false, message: message);
}
