import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'route_names.dart';

// Auth Screens
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/transition_screen.dart';

// Feature Screens
import '../../features/job_logging/presentation/screens/job_list_screen.dart';
import '../../features/job_logging/presentation/screens/log_job_screen.dart';
import '../../features/job_logging/presentation/screens/edit_job_screen.dart';
import '../../features/job_logging/presentation/screens/admin_requests_screen.dart';
import '../../features/whatsapp_followup/presentation/screens/job_detail_screen.dart';
import '../../features/customer_history/presentation/screens/customer_list_screen.dart';
import '../../features/customer_history/presentation/screens/add_customer_screen.dart';
import '../../features/customer_history/presentation/screens/customer_detail_screen.dart';
import '../../features/customer_history/presentation/screens/edit_customer_screen.dart';
import '../../features/key_codes/presentation/screens/key_codes_screen.dart';
import '../../features/knowledge_base/presentation/screens/notes_list_screen.dart';
import '../../features/knowledge_base/presentation/screens/add_note_screen.dart';
import '../../features/knowledge_base/presentation/screens/note_detail_screen.dart';
import '../../features/knowledge_base/presentation/screens/edit_note_screen.dart';
import '../../features/note_links/presentation/screens/note_job_link_screen.dart';
import '../../features/technician_profile/presentation/screens/profile_screen.dart';
import '../../features/technician_profile/presentation/screens/edit_profile_screen.dart';
import '../../features/technician_profile/presentation/screens/public_profile_screen.dart';
import '../../features/service_types/presentation/screens/service_types_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final authState = authStateAsync.valueOrNull ?? const AuthState();

  return GoRouter(
    initialLocation: RouteNames.transition,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublicProfile = path.startsWith('/p/');

      // 1. PUBLIC PROFILE BYPASS
      // If it is a public profile, we NEVER redirect, regardless of auth state.
      if (isPublicProfile) return null;

      // 2. If we are still determining the initial auth state, stay on Transition
      if (state.matchedLocation == RouteNames.transition) {
        if (authStateAsync.isLoading) return null;
        // The TransitionScreen widget will now decide when it is ready to move.
        // We allow it to 'reveal' for a few seconds for branding.
        return null; 
      }

      final isLoggedIn = authState.isAuthenticated;
      final hasProfile = authState.hasProfile;
      
      final isInAuthFlow = path == RouteNames.phoneEntry ||
                           path == RouteNames.otpVerify ||
                           path == RouteNames.landing;
      
      final isOnboarding = path == RouteNames.onboarding;

      // 2. Unauthenticated Path
      if (!isLoggedIn) {
        // If not logged in, we only allow landing/auth flow OR public profiles.
        if (isInAuthFlow || isPublicProfile) return null;
        return RouteNames.landing;
      }

      // 3. Authenticated but No Profile Path
      if (isLoggedIn && !hasProfile) {
        // Allow public profile viewing even if the technician hasn't finished their own onboarding
        if (isOnboarding || isPublicProfile) return null;
        return RouteNames.onboarding;
      }

      // 4. Fully Authenticated Path
      if (isLoggedIn && hasProfile) {
        // If they are trying to access auth/onboarding/transition screens while already fully ready,
        // redirect them to the Dashboard (Jobs), UNLESS they are viewing a public profile.
        if (isPublicProfile) return null;
        
        if (isInAuthFlow || isOnboarding || path == RouteNames.transition) {
          return RouteNames.jobs;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: RouteNames.landing, builder: (context, state) => const LandingScreen()),
      GoRoute(path: RouteNames.phoneEntry, builder: (context, state) => const PhoneEntryScreen()),
      GoRoute(path: RouteNames.otpVerify, builder: (context, state) => const OtpVerifyScreen()),
      GoRoute(path: RouteNames.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: RouteNames.transition, builder: (context, state) => const TransitionScreen()),
      GoRoute(path: RouteNames.jobs, builder: (context, state) => const JobListScreen()),
      GoRoute(path: RouteNames.logJob, builder: (context, state) => LogJobScreen(preSelectedCustomerId: state.extra as String?)),
      GoRoute(path: '/jobs/:id', builder: (context, state) => JobDetailScreen(jobId: state.pathParameters['id']!)),
      GoRoute(path: '/jobs/:id/edit', builder: (context, state) => EditJobScreen(jobId: state.pathParameters['id']!)),
      GoRoute(path: RouteNames.customers, builder: (context, state) => const CustomerListScreen()),
      GoRoute(path: RouteNames.addCustomer, builder: (context, state) => const AddCustomerScreen()),
      GoRoute(path: '/customers/:id', builder: (context, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!)),
      GoRoute(path: '/customers/:id/edit', builder: (context, state) => EditCustomerScreen(customerId: state.pathParameters['id']!)),
      GoRoute(path: '/customers/:id/keycodes', builder: (context, state) => KeyCodesScreen(customerId: state.pathParameters['id']!)),
      GoRoute(path: RouteNames.notes, builder: (context, state) => const NotesListScreen()),
      GoRoute(path: RouteNames.addNote, builder: (context, state) => const AddNoteScreen()),
      GoRoute(path: '/notes/:id', builder: (context, state) => NoteDetailScreen(noteId: state.pathParameters['id']!)),
      GoRoute(path: '/notes/:id/edit', builder: (context, state) => EditNoteScreen(noteId: state.pathParameters['id']!)),
      GoRoute(path: '/notes/:id/link', builder: (context, state) => NoteJobLinkScreen(noteId: state.pathParameters['id']!)),
      GoRoute(path: RouteNames.profile, builder: (context, state) => const ProfileScreen()),
      GoRoute(path: RouteNames.editProfile, builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: RouteNames.serviceTypes, builder: (context, state) => const ServiceTypesScreen()),
      GoRoute(path: RouteNames.adminRequests, builder: (context, state) => const AdminRequestsScreen()),
      GoRoute(path: RouteNames.analytics, builder: (context, state) => const AnalyticsScreen()),
      GoRoute(path: '/p/:slug', builder: (context, state) => PublicProfileScreen(slug: state.pathParameters['slug']!)),
    ],
  );
});
