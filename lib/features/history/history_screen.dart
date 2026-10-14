import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../data/models/meal.dart';
import '../../data/providers/app_providers.dart';

/// History screen displaying meal logs organized by day,
/// enforcing the 3-day history limit for free users with an upgrade prompt.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Meal> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);

    try {
      final isPro = await ref.read(isProProvider.future);
      final mealsRepo = ref.read(mealsRepoProvider);

      // Free users query last 3 days, Pro users query last 30 days
      final daysBack = isPro ? 30 : 3;
      final start = DateTime.now().subtract(Duration(days: daysBack));
      final end = DateTime.now();

      final results = await mealsRepo.getMealsForRange(
        start: start,
        end: end,
        isPro: isPro,
      );

      if (mounted) {
        setState(() {
          _meals = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider).value ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter meals for the selected date
    final selectedDayMeals = _meals.where((m) {
      return m.eatenAt.year == _selectedDate.year &&
          m.eatenAt.month == _selectedDate.month &&
          m.eatenAt.day == _selectedDate.day;
    }).toList();

    final dayCalories = selectedDayMeals.fold<double>(
      0.0,
      (acc, m) => acc + m.totalCalories,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.history),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pro banner for free users
            if (!isPro)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.primaryTeal, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        AppStrings.proHistoryNotice,
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/paywall'),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Date selector strip
            SizedBox(
              height: 74,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: isPro ? 14 : 3, // 14 days for Pro, 3 for Free
                itemBuilder: (context, index) {
                  final date = DateTime.now().subtract(Duration(days: index));
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Formatters.formatDate(date).split(',').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),

            // Selected Day Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatDate(_selectedDate),
                    style: AppTextStyles.titleSmall(context),
                  ),
                  Text(
                    '${dayCalories.round()} kcal total',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            // Meals List
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 3,
                      itemBuilder: (context, i) => LoadingSkeleton.mealItemSkeleton(context),
                    )
                  : selectedDayMeals.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_rounded,
                          title: 'No meals on this day',
                          description: 'Meals logged on this date will appear here.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: selectedDayMeals.length,
                          itemBuilder: (context, index) {
                            final meal = selectedDayMeals[index];
                            return _HistoryMealCard(
                              meal: meal,
                              onDeleted: () {
                                setState(() {
                                  _meals.removeWhere((m) => m.id == meal.id);
                                });
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMealCard extends ConsumerWidget {
  final Meal meal;
  final VoidCallback onDeleted;

  const _HistoryMealCard({required this.meal, required this.onDeleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mealsRepo = ref.read(mealsRepoProvider);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 54,
              height: 54,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              child: meal.imagePath != null
                  ? FutureBuilder<String?>(
                      future: mealsRepo.getSignedImageUrl(meal.imagePath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return CachedNetworkImage(
                            imageUrl: snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return const Icon(Icons.fastfood_rounded, color: AppColors.primaryGreen);
                      },
                    )
                  : const Icon(Icons.restaurant_rounded, color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.items.map((i) => i.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.capitalize(meal.mealType)} • ${Formatters.formatTime(meal.eatenAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatCalories(meal.totalCalories),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Meal'),
                  content: const Text('Remove this meal from history?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(mealsRepoProvider).deleteMeal(meal);
                onDeleted();
              }
            },
          ),
        ],
      ),
    );
  }
}
