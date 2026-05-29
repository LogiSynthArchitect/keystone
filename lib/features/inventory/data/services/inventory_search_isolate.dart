import 'dart:isolate';

/// Message sent from main isolate to the search worker.
/// Contains a query string and a SendPort for the reply.
class _SearchMessage {
  final String query;
  final SendPort replyTo;
  const _SearchMessage(this.query, this.replyTo);
}

/// Entry point for the persistent search Isolate worker.
///
/// Protocol:
///   1. Receive [List<String>] — all search indexes (initial load)
///   2. Receive [_SearchMessage] — a query; reply sent via [replyTo]
void _searchWorker(SendPort mainSend) {
  final receive = ReceivePort();
  mainSend.send(receive.sendPort);

  List<String>? indexes;
  List<int>? allIndices;

  receive.listen((message) {
    if (message is List<String>) {
      // Initial data load
      indexes = message;
      allIndices = List.generate(indexes!.length, (i) => i);
    } else if (message is _SearchMessage) {
      final query = message.query.toLowerCase();
      final replyTo = message.replyTo;
      if (query.isEmpty || indexes == null) {
        replyTo.send(allIndices ?? <int>[]);
        return;
      }
      final matches = <int>[];
      for (int i = 0; i < indexes!.length; i++) {
        if (indexes![i].contains(query)) {
          matches.add(i);
        }
      }
      replyTo.send(matches);
    }
  });
}

/// Manages a persistent background Isolate for inventory search.
///
/// The isolate holds all search indexes in its own memory.
/// Each search call sends only the query string across the boundary.
class InventorySearchIsolate {
  Isolate? _isolate;
  SendPort? _workerSend;
  bool _initialized = false;

  /// Spawn the worker and load [searchIndexes] into it.
  Future<void> initialize(List<String> searchIndexes) async {
    final receive = ReceivePort();
    _isolate = await Isolate.spawn(_searchWorker, receive.sendPort);
    _workerSend = await receive.first as SendPort;
    _workerSend!.send(searchIndexes);
    _initialized = true;
  }

  /// Search all items for [query]. Returns list of matching indices.
  ///
  /// The query is sent across the isolate boundary as a tiny string.
  /// The worker returns indices that match against the pre-loaded indexes.
  Future<List<int>> search(String query) async {
    if (!_initialized) return [];
    final receive = ReceivePort();
    _workerSend!.send(_SearchMessage(query, receive.sendPort));
    final result = await receive.first as List<int>;
    receive.close();
    return result;
  }

  /// Kill the isolate and free resources.
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerSend = null;
    _initialized = false;
  }
}
