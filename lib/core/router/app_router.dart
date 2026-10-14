import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/scan_analysis.dart';
import '../../data/providers/app_providers.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/profile_setup/profile_setup_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/scan/analyzing_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/settings/edit_profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Allow splash, onboarding, forgot password without redirect
      if (loc == '/' || loc == '/onboarding' || loc == '/forgot-password') {
        return null;
      }

      final loggedIn = user != null;
      final isAuthRoute = loc == '/auth';

      if (!loggedIn && !isAuthRoute) {
        return '/auth';
      }

      if (loggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/analyzing',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AnalyzingScreen(
            file: extra['file'] as File,
            mealType: extra['meal_type'] as String? ?? 'lunch',
          );
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResultScreen(
            initialAnalysis: extra['analysis'] as ScanAnalysis,
            imagePath: extra['image_path'] as String,
            localFile: extra['local_file'] as File?,
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
});
