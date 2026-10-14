import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/calorie_ring.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/macro_chip.dart';
import '../../data/models/meal.dart';
import '../../data/providers/app_providers.dart';

/// Home screen showing today's calorie ring, macro distribution, scans remaining,
/// today's meal log grouped by meal type, and the primary Scan button.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.greetingMorning;
    if (hour < 17) return AppStrings.greetingAfternoon;
    return AppStrings.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final remainingScansAsync = ref.watch(remainingScansProvider);
    final isProAsync = ref.watch(isProProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final displayName = profileAsync.value?.displayName ??
        user?.userMetadata?['display_name'] as String? ??
        'Foodie';

    final calorieGoal = profileAsync.value?.dailyCalorieGoal ?? 2000;
    final meals = mealsAsync.value ?? [];

    // Sum today's macros
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;

    for (final meal in meals) {
      totalCalories += meal.totalCalories;
      totalProtein += meal.totalProteinG;
      totalCarbs += meal.totalCarbsG;
      totalFat += meal.totalFatG;
      totalFiber += meal.totalFiberG;
    }

    final isPro = isProAsync.value ?? false;
    final remainingScans = remainingScansAsync.value ?? 3;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async {
            await Future.wait([
              ref.refresh(todayMealsProvider.future),
              ref.refresh(profileNotifierProvider.future),
              ref.refresh(remainingScansProvider.future),
              ref.refresh(isProProvider.future),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Sliver
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            displayName,
                            style: AppTextStyles.titleLarge(context),
                          ),
                        ],
                      ),

                      // Pro / Scan Limit Badge
                      GestureDetector(
                        onTap: () {
                          if (!isPro) context.push('/paywall');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPro
                                ? AppColors.primaryTeal.withValues(alpha: 0.2)
                                : AppColors.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPro
                                  ? AppColors.primaryTeal
                                  : AppColors.primaryGreen.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPro
                                    ? Icons.stars_rounded
                                    : Icons.bolt_rounded,
                                size: 16,
                                color: isPro
                                    ? AppColors.primaryTeal
                                    : AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPro
                                    ? 'PRO'
                                    : '$remainingScans ${AppStrings.scansLeftToday}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isPro
                                      ? AppColors.primaryTeal
                                      : AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Animated Calorie Ring Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CalorieRing(
                      eaten: totalCalories.round(),
                      goal: calorieGoal,
                      size: 200,
                    ),
                  ),
                ),
              ),

              // Macro Distribution Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: MacroChip.protein(totalProtein),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MacroChip.carbs(totalCarbs),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MacroChip.fat(totalFat),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MacroChip.fiber(totalFiber),
                      ),
                    ],
                  ),
                ),
              ),

              // Today's Meals Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.today,
                        style: AppTextStyles.titleMedium(context),
                      ),
                      Text(
                        '${meals.length} logged',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Meal List or Empty / Loading State
              if (mealsAsync.isLoading && meals.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => LoadingSkeleton.mealItemSkeleton(context),
                      childCount: 3,
                    ),
                  ),
                )
              else if (meals.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EmptyState(
                      icon: Icons.dinner_dining_rounded,
                      title: AppStrings.noMealsLoggedToday,
                      description: AppStrings.snapMealPrompt,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final meal = meals[index];
                        return _TodayMealCard(meal: meal);
                      },
                      childCount: meals.length,
                    ),
                  ),
                ),

              // Bottom padding for Floating Action Button
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.push('/history');
          if (index == 2) context.push('/insights');
          if (index == 3) context.push('/settings');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.large(
            onPressed: () {
              if (!isPro && remainingScans <= 0) {
                context.push('/paywall');
              } else {
                context.push('/scan');
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(
              begin: 1.0,
              end: 1.04,
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}

class _TodayMealCard extends ConsumerWidget {
  final Meal meal;

  const _TodayMealCard({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mealsRepo = ref.read(mealsRepoProvider);

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Meal'),
            content: const Text('Are you sure you want to remove this meal from your log?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(todayMealsProvider.notifier).deleteMeal(meal);
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 60,
                height: 60,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                child: meal.imagePath != null
                    ? FutureBuilder<String?>(
                        future: mealsRepo.getSignedImageUrl(meal.imagePath),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return CachedNetworkImage(
                              imageUrl: snapshot.data!,
                              fit: BoxFit.cover,
                              errorWidget: (c, url, err) => const Icon(
                                Icons.fastfood_rounded,
                                color: AppColors.primaryGreen,
                              ),
                            );
                          }
                          return const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.primaryGreen,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Meal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          Formatters.capitalize(meal.mealType),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Formatters.formatTime(meal.eatenAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.items.map((i) => i.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'P: ${Formatters.formatGrams(meal.totalProteinG)} • C: ${Formatters.formatGrams(meal.totalCarbsG)} • F: ${Formatters.formatGrams(meal.totalFatG)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Calories badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCalories(meal.totalCalories),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, 0, Icons.home_rounded, 'Today'),
              _navItem(context, 1, Icons.history_rounded, 'History'),
              const SizedBox(width: 48), // gap for scan FAB
              _navItem(context, 2, Icons.insights_rounded, 'Insights'),
              _navItem(context, 3, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primaryGreen : AppColors.darkTextMuted;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
