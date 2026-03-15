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
import '../../features/whatsapp_followup/presentation/screens/job_detail_screen.dart';
import '../../features/customer_history/presentation/screens/customer_list_screen.dart';
import '../../features/customer_history/presentation/screens/add_customer_screen.dart';
import '../../features/customer_history/presentation/screens/customer_detail_screen.dart';
import '../../features/knowledge_base/presentation/screens/notes_list_screen.dart';
import '../../features/knowledge_base/presentation/screens/add_note_screen.dart';
import '../../features/knowledge_base/presentation/screens/note_detail_screen.dart';
import '../../features/technician_profile/presentation/screens/profile_screen.dart';
import '../../features/technician_profile/presentation/screens/edit_profile_screen.dart';
import '../../features/technician_profile/presentation/screens/public_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final authState = authStateAsync.valueOrNull ?? const AuthState();

  return GoRouter(
    initialLocation: RouteNames.transition,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final hasProfile = authState.hasProfile;
      
      // THE FIX: Added RouteNames.onboarding to the buffer zone
      final isLoggingIn = state.matchedLocation == RouteNames.phoneEntry ||
                          state.matchedLocation == RouteNames.otpVerify ||
                          state.matchedLocation == RouteNames.landing ||
                          state.matchedLocation == RouteNames.onboarding;

      if (state.matchedLocation == RouteNames.transition) return null;

      if (!isLoggedIn) {
        return isLoggingIn ? null : RouteNames.landing;
      }

      if (isLoggedIn && !hasProfile) {
        return state.matchedLocation == RouteNames.onboarding ? null : RouteNames.onboarding;
      }

      if (isLoggedIn && hasProfile && isLoggingIn) {
        return RouteNames.transition;
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
      GoRoute(path: RouteNames.customers, builder: (context, state) => const CustomerListScreen()),
      GoRoute(path: RouteNames.addCustomer, builder: (context, state) => const AddCustomerScreen()),
      GoRoute(path: '/customers/:id', builder: (context, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!)),
      GoRoute(path: RouteNames.notes, builder: (context, state) => const NotesListScreen()),
      GoRoute(path: RouteNames.addNote, builder: (context, state) => const AddNoteScreen()),
      GoRoute(path: '/notes/:id', builder: (context, state) => NoteDetailScreen(noteId: state.pathParameters['id']!)),
      GoRoute(path: RouteNames.profile, builder: (context, state) => const ProfileScreen()),
      GoRoute(path: RouteNames.editProfile, builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/p/:slug', builder: (context, state) => PublicProfileScreen(slug: state.pathParameters['slug']!)),
    ],
  );
});
