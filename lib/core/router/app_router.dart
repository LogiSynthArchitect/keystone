import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/ks_loading_indicator.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/transition_screen.dart';
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
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: RouteNames.landing,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: RouteNames.landing,    name: "landing",    builder: (context, state) => const LandingScreen()),
      GoRoute(path: RouteNames.phoneEntry, name: "phoneEntry", builder: (context, state) => const PhoneEntryScreen()),
      GoRoute(path: RouteNames.otpVerify,  name: "otpVerify",  builder: (context, state) => const OtpVerifyScreen()),
      GoRoute(path: RouteNames.onboarding, name: "onboarding", builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: RouteNames.transition, name: "transition", builder: (context, state) => const TransitionScreen()),
      GoRoute(
        path: RouteNames.jobs,
        name: "jobs",
        builder: (context, state) => const JobListScreen(),
        routes: [
          GoRoute(path: "new",  name: "logJob",    builder: (context, state) => const LogJobScreen()),
          GoRoute(path: ":id",  name: "jobDetail", builder: (context, state) => JobDetailScreen(jobId: state.pathParameters["id"]!)),
        ],
      ),
      GoRoute(
        path: RouteNames.customers,
        name: "customers",
        builder: (context, state) => const CustomerListScreen(),
        routes: [
          GoRoute(path: "new", name: "addCustomer", builder: (context, state) => const AddCustomerScreen()),
          GoRoute(path: ":id", name: "customerDetail", builder: (context, state) => CustomerDetailScreen(customerId: state.pathParameters["id"]!)),
        ],
      ),
      GoRoute(
        path: RouteNames.notes,
        name: "notes",
        builder: (context, state) => const NotesListScreen(),
        routes: [
          GoRoute(path: "new", name: "addNote",    builder: (context, state) => const AddNoteScreen()),
          GoRoute(path: ":id", name: "noteDetail", builder: (context, state) => NoteDetailScreen(noteId: state.pathParameters["id"]!)),
        ],
      ),
      GoRoute(
        path: RouteNames.profile,
        name: "profile",
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(path: "edit", name: "editProfile", builder: (context, state) => const EditProfileScreen()),
        ],
      ),
      GoRoute(
        path: "/p/:slug",
        name: "publicProfile",
        builder: (context, state) => PublicProfileScreen(slug: state.pathParameters["slug"]!),
      ),
    ],
    errorBuilder: (context, state) => const KsLoadingIndicator(fullScreen: true),
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasProfile = false;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, next) {
      _isLoading = next.isLoading;
      _isAuthenticated = next.valueOrNull?.isAuthenticated ?? false;
      _hasProfile = next.valueOrNull?.hasProfile ?? false;
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    if (_isLoading) return null;
    final location = state.matchedLocation;
    final isAuthRoute = location.startsWith("/auth");
    final isPublicRoute = location.startsWith("/p/");
    if (isPublicRoute) return null;
    if (!_isAuthenticated) return (isAuthRoute || location == RouteNames.landing) ? null : RouteNames.landing;
    if (_isAuthenticated && location == RouteNames.transition) return null;
    if (_isAuthenticated && !_hasProfile) return location == RouteNames.onboarding ? null : RouteNames.onboarding;
    if (_isAuthenticated && _hasProfile && isAuthRoute) return RouteNames.jobs;
    return null;
  }
}
