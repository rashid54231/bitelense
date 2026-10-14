import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/providers/app_providers.dart';

/// 3-step swipeable onboarding flow introducing BiteLens and South Asian food AI.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<({String title, String desc, IconData icon, Color color})> _pages = [
    (
      title: AppStrings.onboardingTitle1,
      desc: AppStrings.onboardingDesc1,
      icon: Icons.camera_enhance_rounded,
      color: AppColors.primaryGreen,
    ),
    (
      title: AppStrings.onboardingTitle2,
      desc: AppStrings.onboardingDesc2,
      icon: Icons.restaurant_menu_rounded,
      color: AppColors.carbsColor,
    ),
    (
      title: AppStrings.onboardingTitle3,
      desc: '${AppStrings.onboardingDesc3}\n\n⚠️ ${AppStrings.disclaimerShort}',
      icon: Icons.track_changes_rounded,
      color: AppColors.primaryTeal,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/auth');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: const Text(
              AppStrings.skip,
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final p = _pages[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.color.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(p.icon, size: 70, color: p.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium(context).copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.darkTextSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.primaryGreen
                        : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Next or Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientButton(
                text: _currentPage == _pages.length - 1
                    ? AppStrings.getStarted
                    : AppStrings.next,
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
