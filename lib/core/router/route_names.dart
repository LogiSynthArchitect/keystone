class RouteNames {
  RouteNames._();
  // Auth
  static const String landing     = '/';
  static const String phoneEntry  = '/auth/phone';
  static const String otpVerify   = '/auth/otp';
  static const String onboarding  = '/auth/onboarding';
  static const String transition  = '/auth/transition';
  // Main tabs
  static const String jobs        = '/jobs';
  static const String customers   = '/customers';
  static const String notes       = '/notes';
  static const String profile     = '/profile';
  // Job sub-routes
  static const String logJob      = '/jobs/new';
  static String jobDetail(String id) => '/jobs/$id';
  // Customer sub-routes
  static const String addCustomer = '/customers/new';
  static String customerDetail(String id) => '/customers/$id';
  // Note sub-routes
  static const String addNote     = '/notes/new';
  static String noteDetail(String id) => '/notes/$id';
  // Profile sub-routes
  static const String editProfile = '/profile/edit';
  // Public
  static String publicProfile(String slug) => '/p/$slug';
}
