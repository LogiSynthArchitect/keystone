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

  static const String usersTable          = 'users';
  static const String profilesTable       = 'profiles';
  static const String customersTable      = 'customers';
  static const String jobsTable           = 'jobs';
  static const String knowledgeNotesTable = 'knowledge_notes';
  static const String followUpsTable      = 'follow_ups';
}
