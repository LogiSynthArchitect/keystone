import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/auth_provider.dart';
import 'route_names.dart';
import 'route_transitions.dart';

import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/auth/presentation/screens/create_password_screen.dart';
import '../../features/auth/presentation/screens/password_entry_screen.dart';
import '../../features/auth/presentation/screens/pin_entry_screen.dart';
import '../../features/auth/presentation/screens/biometric_enroll_sheet.dart';
import '../../features/auth/presentation/screens/locked_screen.dart';
import '../../features/auth/presentation/screens/upgrade_account_screen.dart';
import '../../features/auth/presentation/screens/forgot_access_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/transition_screen.dart';
import '../../features/auth/presentation/screens/stale_data_screen.dart';
import '../../features/auth/presentation/screens/initial_sync_screen.dart';
import '../../features/auth/presentation/screens/min_version_gate_screen.dart';
import '../../core/services/internal_auth/models/unlock_result.dart';
import '../../features/job_logging/presentation/screens/job_list_screen.dart';
import '../../features/job_logging/presentation/screens/edit_job_screen.dart';
import '../../features/job_logging/presentation/screens/admin_requests_screen.dart';
import '../../features/job_logging/presentation/screens/job_detail_screen.dart';
import '../../features/customer_history/presentation/screens/customer_list_screen.dart';
import '../../features/customer_history/presentation/screens/add_customer_screen.dart';
import '../../features/customer_history/presentation/screens/customer_detail_screen.dart';
import '../../features/customer_history/presentation/screens/edit_customer_screen.dart';
import '../../features/key_codes/presentation/screens/key_codes_screen.dart';
import '../../features/knowledge_base/presentation/screens/notes_list_screen.dart';
import '../../features/knowledge_base/presentation/screens/add_note_screen.dart';
import '../../features/knowledge_base/presentation/screens/note_detail_screen.dart';
import '../../features/knowledge_base/presentation/screens/edit_note_screen.dart';
import '../../features/technician_profile/presentation/screens/profile_screen.dart';
import '../../features/technician_profile/presentation/screens/edit_profile_screen.dart';
import '../../features/technician_profile/presentation/screens/public_profile_screen.dart';
import '../../features/technician_profile/presentation/screens/permissions_screen.dart';
import '../../features/service_types/presentation/screens/service_types_screen.dart';
import '../../features/service_types/presentation/screens/pricing_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/recurring_jobs/presentation/screens/recurring_schedules_screen.dart';
import '../../features/job_templates/presentation/screens/job_templates_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/reminders/presentation/screens/reminder_settings_screen.dart';
import '../../features/activity_timeline/presentation/screens/timeline_screen.dart';
import '../../features/auth/presentation/screens/setup_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/hub/presentation/screens/hub_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final authState = authStateAsync.valueOrNull ?? const AuthState();

  return GoRouter(
    initialLocation: RouteNames.transition,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublicProfile = path.startsWith('/p/');

      if (isPublicProfile) return null;

      if (state.matchedLocation == RouteNames.transition) {
        if (authStateAsync.isLoading) return null;
        return null;
      }

      final isLoggedIn = authState.isAuthenticated;
      final hasProfile = authState.hasProfile;
      final needsUpgrade = authState.needsPasswordUpgrade;

      final authPaths = [
        RouteNames.landing, RouteNames.phoneEntry, RouteNames.otpVerify,
        RouteNames.createPassword, RouteNames.passwordEntry, RouteNames.pinEntry,
        RouteNames.biometricEnroll, RouteNames.locked, RouteNames.forgotAccess,
        RouteNames.resetPassword,
      ];
      final upgradePath = RouteNames.upgradeAccount;
      final isInAuthFlow = authPaths.contains(path);
      final isOnboarding = path == RouteNames.onboarding;
      final isInPasswordUpgrade = path == upgradePath;

      final authBox = Hive.box('auth');
      final isOutdated = authBox.get('app_is_outdated') as bool? ?? false;
      if (isOutdated && path != RouteNames.versionGate && !isPublicProfile) {
        return RouteNames.versionGate;
      }

      if (!isLoggedIn) {
        if (isInAuthFlow || isPublicProfile) return null;
        return RouteNames.landing;
      }

      if (isLoggedIn && needsUpgrade) {
        if (isPublicProfile) return null;
        if (isInPasswordUpgrade) return null;
        final alreadyUpgraded = authBox.get('password_upgraded') as bool? ?? false;
        if (alreadyUpgraded) return null;
        return RouteNames.upgradeAccount;
      }

      if (isLoggedIn && !hasProfile) {
        if (isOnboarding || isPublicProfile || path == RouteNames.biometricEnroll) return null;
        return RouteNames.onboarding;
      }

      if (isLoggedIn && hasProfile) {
        if (isPublicProfile) return null;
        if (path == RouteNames.initialSync) return null;
        if (isInAuthFlow || isInPasswordUpgrade || isOnboarding || path == RouteNames.transition || path == RouteNames.biometricEnroll) {
          return RouteNames.dashboard;
        }
      }

      if (isLoggedIn && hasProfile) {
        final authBox = Hive.box('auth');
        final syncDone = authBox.get('initial_sync_complete') as bool? ?? false;
        if (!syncDone && path != RouteNames.initialSync && !isPublicProfile) {
          return RouteNames.initialSync;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: RouteNames.landing, builder: (context, state) => const LandingScreen()),
      GoRoute(path: RouteNames.phoneEntry, builder: (context, state) => const PhoneEntryScreen()),
      GoRoute(path: RouteNames.otpVerify, builder: (context, state) => const OtpVerifyScreen()),
      GoRoute(path: RouteNames.createPassword, builder: (context, state) => const CreatePasswordScreen()),
      GoRoute(path: RouteNames.passwordEntry, builder: (context, state) => const PasswordEntryScreen()),
      GoRoute(path: RouteNames.pinEntry, builder: (context, state) => const PinEntryScreen()),
      GoRoute(path: RouteNames.biometricEnroll, builder: (context, state) => const BiometricEnrollPage()),
      GoRoute(path: RouteNames.locked, builder: (context, state) => const LockedScreen()),
      GoRoute(path: RouteNames.upgradeAccount, builder: (context, state) => const UpgradeAccountScreen()),
      GoRoute(path: RouteNames.forgotAccess, builder: (context, state) => const ForgotAccessScreen()),
      GoRoute(path: RouteNames.resetPassword, builder: (context, state) => const ResetPasswordScreen()),
      GoRoute(path: RouteNames.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: RouteNames.staleData, builder: (context, state) => StaleDataScreen(result: state.extra as UnlockNeedsOnline)),
      GoRoute(path: RouteNames.transition, builder: (context, state) => const TransitionScreen()),
      GoRoute(path: RouteNames.initialSync, builder: (context, state) => const InitialSyncScreen()),
      GoRoute(path: RouteNames.versionGate, builder: (context, state) => const MinVersionGateScreen()),
      GoRoute(path: RouteNames.jobs, builder: (context, state) => const JobListScreen()),
      GoRoute(path: RouteNames.dashboard, builder: (context, state) => const DashboardScreen()),
      GoRoute(path: RouteNames.hub, builder: (context, state) => const HubScreen()),
      // LogJobScreen is now a bottom sheet — LogJobScreen.show(context) instead of route push.
      routeWithTransition(path: '/jobs/:id', builder: (context, state) => JobDetailScreen(jobId: state.pathParameters['id']!)),
      routeWithTransition(path: '/jobs/:id/edit', builder: (context, state) => EditJobScreen(jobId: state.pathParameters['id']!)),
      GoRoute(path: RouteNames.customers, builder: (context, state) => const CustomerListScreen()),
      routeWithTransition(path: RouteNames.addCustomer, builder: (context, state) => const AddCustomerScreen()),
      routeWithTransition(path: '/customers/:id', builder: (context, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!)),
      routeWithTransition(path: '/customers/:id/edit', builder: (context, state) => EditCustomerScreen(customerId: state.pathParameters['id']!)),
      routeWithTransition(path: '/customers/:id/keycodes', builder: (context, state) => KeyCodesScreen(customerId: state.pathParameters['id']!)),
      GoRoute(path: RouteNames.notes, builder: (context, state) => const NotesListScreen()),
      routeWithTransition(path: RouteNames.addNote, builder: (context, state) => const AddNoteScreen()),
      routeWithTransition(path: '/notes/:id', builder: (context, state) => NoteDetailScreen(noteId: state.pathParameters['id']!)),
      routeWithTransition(path: '/notes/:id/edit', builder: (context, state) => EditNoteScreen(noteId: state.pathParameters['id']!)),
      // Link screen replaced by bottom sheet — NoteJobLinkScreen.show(context, noteId)
      routeWithTransition(path: RouteNames.profile, builder: (context, state) => const ProfileScreen()),
      routeWithTransition(path: RouteNames.editProfile, builder: (context, state) => const EditProfileScreen()),
      routeWithTransition(path: RouteNames.serviceTypes, builder: (context, state) => const ServiceTypesScreen()),
      routeWithTransition(path: RouteNames.pricing, builder: (context, state) => const PricingScreen()),
      routeWithTransition(path: RouteNames.inventory, builder: (context, state) => const InventoryScreen()),
      routeWithTransition(path: RouteNames.recurringJobs, builder: (context, state) => const RecurringSchedulesScreen()),
      routeWithTransition(path: RouteNames.templates, builder: (context, state) => const JobTemplatesScreen()),
      routeWithTransition(path: RouteNames.adminRequests, builder: (context, state) => const AdminRequestsScreen()),
      routeWithTransition(path: RouteNames.permissions, builder: (context, state) => const PermissionsScreen()),
      routeWithTransition(path: RouteNames.analytics, builder: (context, state) => const AnalyticsScreen()),
      routeWithTransition(path: RouteNames.search, builder: (context, state) => const SearchScreen()),
      routeWithTransition(path: RouteNames.reminders, builder: (context, state) => const RemindersScreen()),
      routeWithTransition(path: RouteNames.reminderSettings, builder: (context, state) => const ReminderSettingsScreen()),
      routeWithTransition(path: RouteNames.timeline, builder: (context, state) => const TimelineScreen()),
      routeWithTransition(path: RouteNames.setup, builder: (context, state) => const SetupScreen()),
      GoRoute(path: '/p/:slug', builder: (context, state) => PublicProfileScreen(slug: state.pathParameters['slug']!)),
    ],
  );
});
