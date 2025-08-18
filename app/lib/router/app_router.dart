import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/app_shell.dart';
import '../features/auth/login_screen.dart';
import '../services/session.dart';
import '../features/auth/password_reset_screen.dart';
import '../features/profile/profile_service.dart';
import 'router_refresh.dart';
import '../features/onboarding/presentation/onboarding_wizard.dart';
import '../features/paywall/paywall_screen.dart';
import 'analytics_observer.dart';
import '../features/diary/diet_screen.dart';
import '../features/diary/supplements_screen.dart';
import '../features/diary/routine_screen.dart';
import '../features/insights/insights_details_screen.dart';

class AppRouter {
  static GoRouter create() {
    final session = SessionService.instance;
    final profile = ProfileService.instance;
    final refresh = MultiListenable([session, profile]);
    return GoRouter(
      initialLocation: '/auth',
      refreshListenable: refresh,
      observers: [AnalyticsNavigatorObserver()],
      redirect: (context, state) {
        final signedIn = session.isSignedIn;
        final loggingIn = state.matchedLocation == '/auth';
        final resetting = state.matchedLocation == '/reset';
        final onboarding = state.matchedLocation == '/onboarding';
        final paywall = state.matchedLocation == '/paywall';

        // Signed-out: only allow auth and reset
        if (!signedIn && !(loggingIn || resetting)) {
          return '/auth';
        }

        // Signed-in and on auth/reset -> push to tabs; further gating below will reroute
        if (signedIn && (loggingIn || resetting)) {
          return '/tabs';
        }

        // If signed-in, gate based on profile
        if (signedIn) {
          final onboarded = profile.onboardingCompleted;
          final hasSub = profile.hasActiveSubscription;

          // If profile not yet loaded, do nothing
          if (onboarded == null) return null;

          if (!onboarded && !onboarding) {
            return '/onboarding';
          }

          if (onboarded && !hasSub && !paywall) {
            return '/paywall';
          }

          // If trying to access onboarding/paywall while fully eligible, go to tabs
          if (onboarded && hasSub && (onboarding || paywall)) {
            return '/tabs';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'root',
          builder: (context, state) => const _PlaceholderScreen(title: 'Root'),
        ),
        GoRoute(
          path: '/auth',
          name: 'auth',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/reset',
          name: 'reset',
          builder: (context, state) => const PasswordResetScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingWizard(),
        ),
        GoRoute(
          path: '/paywall',
          name: 'paywall',
          builder: (context, state) => const PaywallScreen(),
        ),
        GoRoute(
          path: '/tabs',
          name: 'tabs',
          builder: (context, state) => const AppShell(),
        ),
        // Alias: direct insights route opens tabs with Insights selected
        GoRoute(
          path: '/insights',
          name: 'insights',
          builder: (context, state) => const AppShell(initialIndex: 0),
        ),
        GoRoute(
          path: '/insights/details',
          name: 'insights_details',
          builder: (context, state) => const InsightsDetailsScreen(),
        ),
        GoRoute(
          path: '/tabs/:tab',
          name: 'tabs_by_name',
          builder: (context, state) {
            final tab = state.pathParameters['tab']?.toLowerCase();
            final map = {
              'home': 0,
              'insights': 0,
              'diary': 1,
              'chat': 2,
              'profile': 3,
            };
            final index = map[tab] ?? 0;
            return AppShell(initialIndex: index);
          },
        ),
        GoRoute(
          path: '/notifications/:category',
          name: 'notifications_deeplink',
          builder: (context, state) {
            final cat = state.pathParameters['category']?.toLowerCase();
            // Map notification categories to tabs
            final map = {
              'routine': 1, // diary tab where routine actions live
              'log': 1,     // diary/logging
              'insights': 0,
              'chat': 2,
              'profile': 3,
            };
            final index = map[cat] ?? 0;
            return AppShell(initialIndex: index);
          },
        ),
        GoRoute(
          path: '/diet',
          name: 'diet',
          builder: (context, state) => const DietScreen(),
        ),
        GoRoute(
          path: '/supplements',
          name: 'supplements',
          builder: (context, state) => const SupplementsScreen(),
        ),
        GoRoute(
          path: '/routine',
          name: 'routine',
          builder: (context, state) => const RoutineScreen(),
        ),
      ],
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen')),
    );
  }
}
