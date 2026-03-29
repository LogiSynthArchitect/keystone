class SupabaseConstants {
  SupabaseConstants._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String profilePhotosBucket = 'profile-photos';
  static const String notePhotosBucket    = 'note-photos';

  static const String usersTable               = 'users';
  static const String profilesTable            = 'profiles';
  static const String customersTable           = 'customers';
  static const String jobsTable                = 'jobs';
  static const String knowledgeNotesTable      = 'knowledge_notes';
  static const String followUpsTable           = 'follow_ups';
  static const String correctionRequestsTable  = 'correction_requests';
  static const String appEventsTable           = 'app_events';
  static const String serviceTypesTable       = 'service_types';
  static const String jobPartsTable           = 'job_parts';
  static const String jobPhotosTable          = 'job_photos';
  static const String jobAuditLogTable        = 'job_audit_log';
  static const String keyCodeHistoryTable     = 'key_code_history';
  static const String noteJobLinksTable       = 'note_job_links';
  static const String remindersTable          = 'reminders';
  static const String activityEventsTable     = 'activity_events';
}
