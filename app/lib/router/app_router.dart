import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/app_shell.dart';
import '../app/tracking_app_shell.dart';
import '../features/auth/login_screen.dart';
import '../services/session.dart';
import '../features/auth/password_reset_screen.dart';
import '../features/profile/profile_service.dart';
import 'router_refresh.dart';
import '../features/onboarding/presentation/enhanced_onboarding_flow.dart';
import '../features/paywall/paywall_screen_v2.dart';
import '../features/paywall/trial_offer_screen.dart';
import 'analytics_observer.dart';
import '../features/diary/diet_screen.dart';
import '../features/diary/supplements_screen.dart';
import '../features/diary/routine_screen.dart';
import '../features/insights/insights_details_screen.dart';
import '../widgets/page_transitions.dart';
import '../features/referrals/presentation/share_success_screen.dart';

class AppRouter {
  static GoRouter create() {
    final session = SessionService.instance;
    final profile = ProfileService.instance;
    final refresh = MultiListenable([session, profile]);
    return GoRouter(
      initialLocation: '/onboarding',
      refreshListenable: refresh,
      observers: [AnalyticsNavigatorObserver()],
      redirect: (context, state) {
        final signedIn = session.isSignedIn;
        final loggingIn = state.matchedLocation == '/auth';
        final resetting = state.matchedLocation == '/reset';
        final onboarding = state.matchedLocation == '/onboarding';
        final paywall = state.matchedLocation == '/paywall';
        final trialOffer = state.matchedLocation == '/trial-offer';

        // Signed-out: allow onboarding, auth, and reset only
        if (!signedIn && !(loggingIn || resetting || onboarding)) {
          return '/onboarding';
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

          if (onboarded && !hasSub && !paywall && !trialOffer) {
            return '/trial-offer';
          }

          // If trying to access onboarding/paywall/trial while fully eligible, go to tabs
          if (onboarded && hasSub && (onboarding || paywall || trialOffer)) {
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
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const EnhancedOnboardingFlow(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Check for reduced motion
              final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
              if (reducedMotion) return child;
              
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.linear,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: '/trial-offer',
          name: 'trial_offer',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const TrialOfferScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
              if (reducedMotion) return child;
              
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.linear,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: '/paywall',
          name: 'paywall',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PaywallScreenV2(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Check for reduced motion
              final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
              if (reducedMotion) return child;
              
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.linear,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: '/share-success',
          name: 'share_success',
          builder: (context, state) {
            final donorName = state.extra as String?;
            return ShareSuccessScreen(donorName: donorName);
          },
        ),
        GoRoute(
          path: '/tabs',
          name: 'tabs',
          builder: (context, state) => const TrackingAppShell(),
        ),
        // Alias: direct insights route opens tabs with Home selected
        GoRoute(
          path: '/insights',
          name: 'insights',
          builder: (context, state) => const TrackingAppShell(initialIndex: 0),
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
            // New navigation: Home(0), Symptoms(1), Routine(2), Supps(3), Chat(4)
            final map = {
              'home': 0,
              'insights': 0,
              'symptoms': 1,
              'routine': 2,
              'supps': 3,
              'supplements': 3,
              'chat': 4,
            };
            final index = map[tab] ?? 0;
            return TrackingAppShell(initialIndex: index);
          },
        ),
        GoRoute(
          path: '/notifications/:category',
          name: 'notifications_deeplink',
          builder: (context, state) {
            final cat = state.pathParameters['category']?.toLowerCase();
            // Map notification categories to tabs
            // New navigation: Home(0), Symptoms(1), Routine(2), Supps(3), Chat(4)
            final map = {
              'routine': 2,
              'log': 0,
              'insights': 0,
              'chat': 4,
              'supplements': 3,
            };
            final index = map[cat] ?? 0;
            return TrackingAppShell(initialIndex: index);
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
