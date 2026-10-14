import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/macro_chip.dart';
import '../../data/models/meal.dart';
import '../../data/providers/app_providers.dart';

/// Insights screen showing weekly calorie intake bar chart, macro split,
/// logging streak, and blurred paywall overlay for free users.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  List<Meal> _pastMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPastWeek();
  }

  Future<void> _fetchPastWeek() async {
    try {
      final isPro = await ref.read(isProProvider.future);
      final start = DateTime.now().subtract(const Duration(days: 7));
      final end = DateTime.now();

      final results = await ref.read(mealsRepoProvider).getMealsForRange(
        start: start,
        end: end,
        isPro: isPro,
      );

      if (mounted) {
        setState(() {
          _pastMeals = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.insights)),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isPro = ref.watch(isProProvider).value ?? false;

    // Compute weekly data: last 7 days daily calories
    final now = DateTime.now();
    final dayTotals = <int, double>{};
    for (int i = 0; i < 7; i++) {
      dayTotals[i] = 0.0;
    }

    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    final loggedDays = <String>{};

    for (final meal in _pastMeals) {
      final diff = now.difference(meal.eatenAt).inDays;
      if (diff >= 0 && diff < 7) {
        final dayIndex = 6 - diff;
        dayTotals[dayIndex] = (dayTotals[dayIndex] ?? 0.0) + meal.totalCalories;
      }
      totalProtein += meal.totalProteinG;
      totalCarbs += meal.totalCarbsG;
      totalFat += meal.totalFatG;

      loggedDays.add(
        '${meal.eatenAt.year}-${meal.eatenAt.month}-${meal.eatenAt.day}',
      );
    }

    final double avgCalories = dayTotals.values.reduce((a, b) => a + b) / 7;
    final int streakDays = loggedDays.length;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat cards: Average Calories and Day Streak
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.weeklyAverage,
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${avgCalories.round()} kcal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.loggingStreak,
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            '$streakDays Days',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly Calorie Bar Chart
          Text(
            AppStrings.weeklyCalorieChart,
            style: AppTextStyles.titleMedium(context),
          ),
          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 3000,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final idx = val.toInt();
                          if (idx >= 0 && idx < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[idx],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white60,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final cal = dayTotals[i] ?? 0.0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: cal > 0 ? cal : 150, // subtle placeholder height if empty
                          gradient: AppColors.accentGradient,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Macro Distribution
          Text(
            AppStrings.macroDistribution,
            style: AppTextStyles.titleMedium(context),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: MacroChip.protein(totalProtein)),
              const SizedBox(width: 8),
              Expanded(child: MacroChip.carbs(totalCarbs)),
              const SizedBox(width: 8),
              Expanded(child: MacroChip.fat(totalFat)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.insights)),
      body: SafeArea(
        child: isPro
            ? content
            : Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred content preview
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: content,
                  ),

                  // Paywall overlay banner
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primaryTeal, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              size: 32,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unlock Pro Insights',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Track weekly calorie intake trends, macro balance, and nutrition streaks with BiteLens Pro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(
                            text: 'View Pro Plans',
                            onPressed: () => context.push('/paywall'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
