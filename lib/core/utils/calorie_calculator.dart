/// Calorie calculator implementing the Mifflin-St Jeor equation
/// with activity multipliers, goal adjustments, and safety floors.
class CalorieCalculator {
  CalorieCalculator._();

  static const int minCalorieFloor = 1200;

  /// Calculates Basal Metabolic Rate (BMR) using Mifflin-St Jeor.
  /// [weightKg]: Body weight in kilograms
  /// [heightCm]: Height in centimeters
  /// [ageYears]: Age in years
  /// [sex]: 'male', 'female', or 'other'
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required String sex,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || ageYears <= 0) {
      return 1500.0;
    }

    // Base: 10*weight + 6.25*height - 5*age
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * ageYears);

    switch (sex.toLowerCase()) {
      case 'male':
        return base + 5.0;
      case 'female':
        return base - 161.0;
      default:
        // Average of male (+5) and female (-161)
        return base - 78.0;
    }
  }

  /// Activity multipliers based on standard fitness guidelines
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'active':
        return 1.725;
      case 'very_active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  /// Goal calorie adjustment:
  /// lose: -500 kcal
  /// maintain: 0 kcal
  /// gain: +300 kcal
  static int getGoalAdjustment(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose':
        return -500;
      case 'gain':
        return 300;
      case 'maintain':
      default:
        return 0;
    }
  }

  /// Calculates total recommended daily calories.
  /// Applies BMR * activityMultiplier + goalAdjustment,
  /// enforced to a minimum floor of [minCalorieFloor] (1200 kcal).
  static int calculateDailyGoal({
    required double weightKg,
    required double heightCm,
    required int birthYear,
    required String sex,
    required String activityLevel,
    required String goal,
    int? currentYear,
  }) {
    final nowYear = currentYear ?? DateTime.now().year;
    final age = (nowYear - birthYear).clamp(10, 110);

    final bmr = calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: age,
      sex: sex,
    );

    final tdee = bmr * getActivityMultiplier(activityLevel);
    final adjusted = (tdee + getGoalAdjustment(goal)).round();

    // Never drop below 1200 kcal
    return adjusted < minCalorieFloor ? minCalorieFloor : adjusted;
  }

  /// Calculates portion-scaled nutrition when user changes grams
  static Map<String, dynamic> rescaleNutrients({
    required double originalGrams,
    required double newGrams,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
  }) {
    if (originalGrams <= 0 || newGrams <= 0) {
      return {
        'calories': calories,
        'protein_g': protein,
        'carbs_g': carbs,
        'fat_g': fat,
        'fiber_g': fiber,
      };
    }

    final ratio = newGrams / originalGrams;
    return {
      'calories': (calories * ratio).roundToDouble(),
      'protein_g': ((protein * ratio) * 10).round() / 10.0,
      'carbs_g': ((carbs * ratio) * 10).round() / 10.0,
      'fat_g': ((fat * ratio) * 10).round() / 10.0,
      'fiber_g': ((fiber * ratio) * 10).round() / 10.0,
    };
  }
}
