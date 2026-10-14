import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/providers/app_providers.dart';

/// Splash screen that checks onboarding status, auth session, and profile completion.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNextDestination();
  }

  Future<void> _checkNextDestination() async {
    // Brief pause for splash animation to show brand
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final onboardingSeen = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingSeen) {
      context.go('/onboarding');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/auth');
      return;
    }

    // Check if profile is completed
    try {
      final profile = await ref.read(profileRepoProvider).getProfile();
      if (!mounted) return;

      if (profile == null || !profile.onboardingDone) {
        context.go('/profile-setup');
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BiteLens Brand Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 46,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 1200.ms),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: AppTextStyles.displayMedium(context).copyWith(
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              AppStrings.appTagline,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
