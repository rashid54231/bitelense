import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/models/profile.dart';
import '../../data/providers/app_providers.dart';

/// Screen allowing users to update their profile metrics and recalculate their calorie target.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _overrideController;

  String _sex = 'male';
  int _birthYear = 1995;
  double _heightCm = 170.0;
  double _weightKg = 70.0;
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  int _calculatedGoal = 2000;
  int _finalGoal = 2000;
  bool _manualOverride = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileNotifierProvider).value;

    _sex = profile?.sex ?? 'male';
    _birthYear = profile?.birthYear ?? 1995;
    _heightCm = profile?.heightCm ?? 170.0;
    _weightKg = profile?.weightKg ?? 70.0;
    _activityLevel = profile?.activityLevel ?? 'moderate';
    _goal = profile?.goal ?? 'maintain';
    _finalGoal = profile?.dailyCalorieGoal ?? 2000;

    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _heightController = TextEditingController(text: _heightCm.round().toString());
    _weightController = TextEditingController(text: _weightKg.round().toString());
    _overrideController = TextEditingController(text: _finalGoal.toString());

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
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _overrideController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updated = Profile(
        id: user.id,
        displayName: _nameController.text.trim(),
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

      await ref.read(profileNotifierProvider.notifier).updateProfile(updated);

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Profile updated successfully!');
      context.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile & Goals')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.displayName,
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // Height and Weight
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: AppStrings.height,
                          suffixText: 'cm',
                        ),
                        onChanged: (val) {
                          final n = double.tryParse(val);
                          if (n != null && n > 0) {
                            _heightCm = n;
                            _recalculate();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: AppStrings.weight,
                          suffixText: 'kg',
                        ),
                        onChanged: (val) {
                          final n = double.tryParse(val);
                          if (n != null && n > 0) {
                            _weightKg = n;
                            _recalculate();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Activity Level
                DropdownButtonFormField<String>(
                  initialValue: _activityLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: AppStrings.activityLevel),
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
                const SizedBox(height: 16),

                // Goal
                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  decoration: const InputDecoration(labelText: AppStrings.goal),
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
                const SizedBox(height: 20),

                // Calorie Target Card
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Calculated Target:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '$_calculatedGoal kcal',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                          const Text('Use custom calorie target'),
                        ],
                      ),
                      if (_manualOverride) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _overrideController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Custom Target (kcal)',
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
                  text: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
