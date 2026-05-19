sealed class UnlockResult {}

class UnlockSuccess extends UnlockResult {}

class UnlockLocked extends UnlockResult {
  final String reason;
  UnlockLocked(this.reason);
}

class UnlockNeedsNetwork extends UnlockResult {
  final String reason;
  UnlockNeedsNetwork(this.reason);
}

class UnlockNeedsOnline extends UnlockResult {
  final DateTime? lastSync;
  final String reason;
  UnlockNeedsOnline({this.lastSync, required this.reason});
}
