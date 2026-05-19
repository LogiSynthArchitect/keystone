class RouteNames {
  RouteNames._();
  // Auth
  static const String landing        = '/';
  static const String phoneEntry     = '/auth/phone';
  static const String otpVerify      = '/auth/otp';
  static const String createPassword = '/auth/create-password';
  static const String passwordEntry  = '/auth/password';
  static const String pinEntry       = '/auth/pin';
  static const String biometricEnroll = '/auth/biometric-enroll';
  static const String locked         = '/auth/locked';
  static const String upgradeAccount = '/auth/upgrade';
  static const String forgotAccess   = '/auth/forgot';
  static const String resetPassword  = '/auth/reset';
  static const String onboarding     = '/auth/onboarding';
  static const String staleData      = '/auth/stale';
  static const String initialSync    = '/auth/initial-sync';
  static const String versionGate    = '/auth/version-gate';
  static const String transition     = '/auth/transition';
  // Main tabs
  static const String dashboard  = '/dashboard';
  static const String jobs        = '/jobs';
  static const String customers   = '/customers';
  static const String notes       = '/notes';
  static const String profile     = '/profile';
  static const String hub         = '/hub';
  // Job sub-routes
  static const String logJob      = '/jobs/new';
  static String jobDetail(String id) => '/jobs/$id';
  static String editJob(String id) => '/jobs/$id/edit';
  // Customer sub-routes
  static const String addCustomer = '/customers/new';
  static String customerDetail(String id) => '/customers/$id';
  static String editCustomer(String id) => '/customers/$id/edit';
  static String customerKeyCodes(String id) => '/customers/$id/keycodes';
  // Note sub-routes
  static const String addNote     = '/notes/new';
  static String noteDetail(String id) => '/notes/$id';
  static String editNote(String id) => '/notes/$id/edit';
  static String noteLinkJobs(String id) => '/notes/$id/link';
  // Analytics
  static const String analytics    = '/analytics';
  // Search
  static const String search       = '/search';
  // Reminders
  static const String reminders    = '/reminders';
  static const String reminderSettings = '/profile/reminder-settings';
  // Activity timeline
  static const String timeline     = '/activity';
  // Profile sub-routes
  static const String editProfile = '/profile/edit';
  static const String serviceTypes = '/profile/service-types';
  static const String pricing   = '/profile/pricing';
  static const String inventory   = '/profile/inventory';
  static const String templates   = '/profile/templates';
  static const String recurringJobs = '/profile/recurring-jobs';
  static const String adminRequests = '/admin/requests';
  static const String permissions = '/admin/permissions';
  // Setup flow
  static const String setup = '/setup';
  // Public
  static String publicProfile(String slug) => '/p/$slug';
}
