import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/profile.dart';
import '../../data/providers/app_providers.dart';

/// Profile setup screen with dynamic Mifflin-St Jeor calorie calculation.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  String _sex = 'male';
  int _birthYear = 1998;
  double _heightCm = 172.0;
  double _weightKg = 72.0;
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  int _calculatedGoal = 2000;
  bool _manualOverride = false;
  int _finalGoal = 2000;
  bool _isLoading = false;

  final TextEditingController _heightController = TextEditingController(text: '172');
  final TextEditingController _weightController = TextEditingController(text: '72');
  final TextEditingController _overrideController = TextEditingController(text: '2000');

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final calc = CalorieCalculator.calculateDailyGoal(
      weightKg: _weightKg,
      heightCm: _heightCm,
      birthYear: _birthYear,
      sex: _sex,
      activityLevel: _activityLevel,
      goal: _goal,
    );

    setState(() {
      _calculatedGoal = calc;
      if (!_manualOverride) {
        _finalGoal = calc;
        _overrideController.text = calc.toString();
      }
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _overrideController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/auth');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = Profile(
        id: user.id,
        displayName: user.userMetadata?['display_name'] as String?,
        sex: _sex,
        birthYear: _birthYear,
        heightCm: _heightCm,
        weightKg: _weightKg,
        activityLevel: _activityLevel,
        goal: _goal,
        dailyCalorieGoal: _finalGoal,
        units: 'metric',
        onboardingDone: true,
      );

      await ref.read(profileNotifierProvider.notifier).updateProfile(profile);

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Profile and calorie target saved!');
      context.go('/home');
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileSetupTitle),
        actions: [
          TextButton(
            onPressed: _saveAndContinue,
            child: const Text(
              AppStrings.skip,
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.profileSetupSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Sex Selection
                const Text(
                  AppStrings.sex,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRadioChip('male', AppStrings.male),
                    const SizedBox(width: 8),
                    _buildRadioChip('female', AppStrings.female),
                    const SizedBox(width: 8),
                    _buildRadioChip('other', AppStrings.other),
                  ],
                ),
                const SizedBox(height: 18),

                // Height and Weight
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.height,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(suffixText: 'cm'),
                            onChanged: (val) {
                              final numVal = double.tryParse(val);
                              if (numVal != null && numVal > 0) {
                                _heightCm = numVal;
                                _recalculate();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.weight,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(suffixText: 'kg'),
                            onChanged: (val) {
                              final numVal = double.tryParse(val);
                              if (numVal != null && numVal > 0) {
                                _weightKg = numVal;
                                _recalculate();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Birth Year Dropdown
                const Text(
                  AppStrings.birthYear,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _birthYear,
                  decoration: const InputDecoration(),
                  items: List.generate(
                    70,
                    (idx) => DropdownMenuItem(
                      value: DateTime.now().year - 15 - idx,
                      child: Text('${DateTime.now().year - 15 - idx}'),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      _birthYear = val;
                      _recalculate();
                    }
                  },
                ),
                const SizedBox(height: 18),

                // Activity Level Dropdown
                const Text(
                  AppStrings.activityLevel,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _activityLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'sedentary', child: Text(AppStrings.sedentary)),
                    DropdownMenuItem(value: 'light', child: Text(AppStrings.light)),
                    DropdownMenuItem(value: 'moderate', child: Text(AppStrings.moderate)),
                    DropdownMenuItem(value: 'active', child: Text(AppStrings.active)),
                    DropdownMenuItem(value: 'very_active', child: Text(AppStrings.veryActive)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _activityLevel = val;
                      _recalculate();
                    }
                  },
                ),
                const SizedBox(height: 18),

                // Goal Dropdown
                const Text(
                  AppStrings.goal,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'lose', child: Text(AppStrings.loseWeight)),
                    DropdownMenuItem(value: 'maintain', child: Text(AppStrings.maintainWeight)),
                    DropdownMenuItem(value: 'gain', child: Text(AppStrings.gainWeight)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _goal = val;
                      _recalculate();
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Calculated Results Card
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.calculatedGoal,
                            style: AppTextStyles.titleSmall(context),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_calculatedGoal kcal',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _manualOverride,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (val) {
                              setState(() {
                                _manualOverride = val ?? false;
                                if (!_manualOverride) {
                                  _finalGoal = _calculatedGoal;
                                  _overrideController.text = _calculatedGoal.toString();
                                }
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Set custom daily goal',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (_manualOverride) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _overrideController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.manualOverride,
                            suffixText: 'kcal',
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed >= 1200) {
                              _finalGoal = parsed;
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                GradientButton(
                  text: AppStrings.saveProfile,
                  isLoading: _isLoading,
                  onPressed: _saveAndContinue,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioChip(String value, String label) {
    final isSelected = _sex == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _sex = value;
            _recalculate();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.2)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryGreen : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
