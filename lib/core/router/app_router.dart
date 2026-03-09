import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.jobs,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // While auth is loading — allow through
      if (authAsync.isLoading) return null;

      final auth = authAsync.valueOrNull;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final hasProfile = auth?.hasProfile ?? false;
      final location = state.matchedLocation;

      // Public routes — always allow
      final isPublicRoute =
          location.startsWith('/auth') || location.startsWith('/p/');
      if (isPublicRoute) return null;

      // No session — send to phone entry
      if (!isAuthenticated) return RouteNames.phoneEntry;

      // Session but no profile — send to onboarding
      if (isAuthenticated && !hasProfile) {
        if (location == RouteNames.onboarding) return null;
        return RouteNames.onboarding;
      }

      // Fully authenticated hitting auth routes — send to jobs
      if (isAuthenticated && hasProfile && location.startsWith('/auth')) {
        return RouteNames.jobs;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.phoneEntry,
        name: 'phoneEntry',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Phone Entry — coming soon')),
        ),
      ),
      GoRoute(
        path: RouteNames.otpVerify,
        name: 'otpVerify',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OTP Verify — coming soon')),
        ),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Onboarding — coming soon')),
        ),
      ),
      GoRoute(
        path: '/p/:slug',
        name: 'publicProfile',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Public Profile: ${state.pathParameters['slug']}'),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.jobs,
        name: 'jobs',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Jobs — coming soon')),
        ),
      ),
      GoRoute(
        path: RouteNames.customers,
        name: 'customers',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Customers — coming soon')),
        ),
      ),
      GoRoute(
        path: RouteNames.notes,
        name: 'notes',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Notes — coming soon')),
        ),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Profile — coming soon')),
        ),
      ),
    ],
  );
});
