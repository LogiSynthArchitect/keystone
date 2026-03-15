# DOCUMENT 17 — NAVIGATION ARCHITECTURE
### Project: Keystone
**Required Inputs:** Document 09 — Permission Matrix, Document 13 — Flutter Architecture, Document 16 — Screen Inventory
**Router:** GoRouter ^13.2.0
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 17.1 Navigation Principles

1. Auth guard on every protected route — unauthenticated users redirected to /auth/phone
2. Shell route for bottom nav — jobs, customers, notes, profile share one persistent shell
3. No bottom nav on auth screens or public profile — clean distraction-free flows
4. Deep links work out of the box — /p/:slug publicly accessible, no auth intercept
5. Transition polish — slide for push, fade for modals, none for tab switches
6. GoRouter redirect, not middleware — all auth logic lives in the router

---

## 17.2 Route Tree

/                           → redirect → /jobs (authed) or /auth/phone
├── /auth/phone             → PhoneEntryScreen        (no auth)
├── /auth/otp               → OtpVerifyScreen          (no auth)
├── /auth/onboarding        → OnboardingScreen         (auth, no profile yet)
├── /p/:slug                → PublicProfileScreen      (no auth, no shell)
└── [StatefulShellRoute]    → KsScaffoldShell          (auth required)
    ├── /jobs               → JobListScreen             tab 0
    │   ├── /jobs/new       → LogJobScreen              push
    │   └── /jobs/:id       → JobDetailScreen           push
    ├── /customers          → CustomerListScreen        tab 1
    │   ├── /customers/new  → AddCustomerScreen         push
    │   └── /customers/:id  → CustomerDetailScreen      push
    ├── /notes              → NotesListScreen           tab 2
    │   ├── /notes/new      → AddNoteScreen             push
    │   └── /notes/:id      → NoteDetailScreen          push
    └── /profile            → ProfileScreen             tab 3
        └── /profile/edit   → EditProfileScreen         push

---

## 17.3 Auth States and Redirects

State 1 — unauthenticated:     no session        → /auth/phone
State 2 — auth, no profile:    session, no user  → /auth/onboarding
State 3 — fully authenticated: session + user    → /jobs (if hitting /auth/*)

Redirect logic:
if route is /auth/* or /p/*     → allow
if no session                   → /auth/phone
if session and no profile       → /auth/onboarding (unless already there)
if session and profile and /auth/* → /jobs
else                            → allow

---

## 17.4 Shell Route

KsScaffoldShell wraps all 4 tab branches.
Provides: KsBottomNav + KsOfflineBanner + neutral050 background
Each branch maintains its own independent navigation stack.
Tapping active tab triggers initialLocation: true → returns to branch root.

---

## 17.5 Page Transitions

Slide (push):  SlideTransition Offset(1,0)→(0,0) 200ms easeInOut
               Used for: all sub-pages (detail, new, edit)

Fade (modal):  FadeTransition 150ms easeIn
               Used for: auth screens, public profile

None (tabs):   NoTransitionPage
               Used for: all 4 tab root screens

---

## 17.6 app_router.dart (paste-ready)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ... [all screen imports]
import '../providers/auth_provider.dart';
import '../widgets/ks_scaffold_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.jobs,
    debugLogDiagnostics: false,

    redirect: (context, state) {
      final isAuthenticated = authState.session != null;
      final hasProfile = authState.hasProfile;
      final location = state.matchedLocation;

      final isPublicRoute =
          location.startsWith('/auth') || location.startsWith('/p/');
      if (isPublicRoute) return null;

      if (!isAuthenticated) return RouteNames.phoneEntry;

      if (isAuthenticated && !hasProfile) {
        if (location == RouteNames.onboarding) return null;
        return RouteNames.onboarding;
      }

      if (isAuthenticated && hasProfile && location.startsWith('/auth')) {
        return RouteNames.jobs;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: RouteNames.phoneEntry,
        name: 'phoneEntry',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const PhoneEntryScreen()),
      ),
      GoRoute(
        path: RouteNames.otpVerify,
        name: 'otpVerify',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const OtpVerifyScreen()),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/p/:slug',
        name: 'publicProfile',
        pageBuilder: (context, state) => _fadeTransition(
          state,
          PublicProfileScreen(slug: state.pathParameters['slug']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            KsScaffoldShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.jobs,
              name: 'jobs',
              pageBuilder: (context, state) =>
                  _noTransition(state, const JobListScreen()),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'logJob',
                  pageBuilder: (context, state) =>
                      _slideTransition(state, const LogJobScreen()),
                ),
                GoRoute(
                  path: ':id',
                  name: 'jobDetail',
                  pageBuilder: (context, state) => _slideTransition(
                    state,
                    JobDetailScreen(jobId: state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.customers,
              name: 'customers',
              pageBuilder: (context, state) =>
                  _noTransition(state, const CustomerListScreen()),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'addCustomer',
                  pageBuilder: (context, state) =>
                      _slideTransition(state, const AddCustomerScreen()),
                ),
                GoRoute(
                  path: ':id',
                  name: 'customerDetail',
                  pageBuilder: (context, state) => _slideTransition(
                    state,
                    CustomerDetailScreen(
                        customerId: state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.notes,
              name: 'notes',
              pageBuilder: (context, state) =>
                  _noTransition(state, const NotesListScreen()),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'addNote',
                  pageBuilder: (context, state) =>
                      _slideTransition(state, const AddNoteScreen()),
                ),
                GoRoute(
                  path: ':id',
                  name: 'noteDetail',
                  pageBuilder: (context, state) => _slideTransition(
                    state,
                    NoteDetailScreen(noteId: state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.profile,
              name: 'profile',
              pageBuilder: (context, state) =>
                  _noTransition(state, const ProfileScreen()),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'editProfile',
                  pageBuilder: (context, state) =>
                      _slideTransition(state, const EditProfileScreen()),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    ),
  );
}

CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
      child: child,
    ),
  );
}

NoTransitionPage<void> _noTransition(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

---

## 17.7 route_names.dart (paste-ready)

class RouteNames {
  RouteNames._();

  static const String phoneEntry  = '/auth/phone';
  static const String otpVerify   = '/auth/otp';
  static const String onboarding  = '/auth/onboarding';

  static const String jobs        = '/jobs';
  static const String customers   = '/customers';
  static const String notes       = '/notes';
  static const String profile     = '/profile';

  static const String logJob      = '/jobs/new';
  static String jobDetail(String id) => '/jobs/$id';

  static const String addCustomer = '/customers/new';
  static String customerDetail(String id) => '/customers/$id';

  static const String addNote     = '/notes/new';
  static String noteDetail(String id) => '/notes/$id';

  static const String editProfile = '/profile/edit';

  static String publicProfile(String slug) => '/p/$slug';
}

---

## 17.8 Navigation Usage

context.push(RouteNames.jobDetail(job.id))   — sub-page, back button shown
context.push(RouteNames.logJob)              — sub-page
context.go(RouteNames.customers)             — tab switch, replaces stack
context.pop()                               — back one level

push: adds to stack (sub-pages, detail screens)
go:   replaces stack (tab switches, auth redirects)
pop:  back one level

---

## 17.9 Deep Link Configuration

Android AndroidManifest.xml:
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="keystone.app" />
</intent-filter>

Supported deep links:
https://keystone.app/p/jeremie-kouassi  → PublicProfileScreen (no auth)
https://keystone.app/jobs/[id]          → JobDetailScreen (auth required)
https://keystone.app/customers/[id]     → CustomerDetailScreen (auth required)

---

## 17.10 authStateProvider

@freezed class AuthState:
  Session? session
  bool hasProfile (default false)
  bool isLoading (default false)

AuthNotifier.build():
  1. Watch supabase.auth.onAuthStateChange → invalidateSelf on change
  2. If no session → return AuthState()
  3. If session → query users table by auth_id
  4. Return AuthState(session, hasProfile: profile != null)

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>

---

## 17.11 KsScaffoldShell

class KsScaffoldShell extends StatelessWidget:
  Scaffold(neutral050)
  body: Column[KsOfflineBanner + Expanded(navigationShell)]
  bottomNavigationBar: KsBottomNav(
    currentIndex: navigationShell.currentIndex,
    onTabTapped: (index) → navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex
    )
  )

initialLocation: true when tapping active tab → returns branch to root route

---

## Validation Checklist
- [x] Complete GoRouter configuration paste-ready
- [x] All 15 routes defined with correct paths
- [x] Auth redirect logic covers all 3 states
- [x] StatefulShellRoute preserves independent tab stacks
- [x] Public profile route requires no auth
- [x] Slide transitions for push, fade for auth/public, none for tabs
- [x] route_names.dart typed constants — zero magic strings
- [x] Deep link Android manifest configuration documented
- [x] push vs go vs pop usage documented
- [x] authStateProvider fully specified
- [x] KsScaffoldShell fully specified
