const _minute = Duration(minutes: 1);

const cacheTTL = {
  'jobs': Duration(minutes: 5),
  'customers': Duration(minutes: 5),
  'notes': Duration(minutes: 15),
  'analytics': Duration(minutes: 2),
  'service_types': Duration(minutes: 30),
  'activity': Duration(minutes: 10),
};

const syncStrategy = '''
SYNC STRATEGY — Cache-first, last-writer-wins
  Reads:     Local (Hive) first, then remote fetch + cache update.
             If remote fails, serve stale cache silently.
  Writes:    Local first (instant), then async remote sync.
             Remote failures queue as sync_status=pending for retry.
  Conflicts: Server timestamp wins. If remote updated_at > local updated_at,
             remote replaces local. Logged as audit entry 'conflict_resolved'.
  Retry:     Connectivity listener triggers full refresh on reconnection.
             Pending queue drained on refresh() with batch RPC.
  Pagination: Jobs/Notes use in-memory pagination (displayLimit + loadMore).
              Full dataset loaded from Hive, UI shows page-sized chunks.
''';
