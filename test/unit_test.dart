import 'package:flutter_test/flutter_test.dart';
import 'package:bitelens_app/core/utils/calorie_calculator.dart';
import 'package:bitelens_app/core/utils/formatters.dart';
import 'package:bitelens_app/data/models/meal.dart';
import 'package:bitelens_app/data/models/meal_item.dart';
import 'package:bitelens_app/data/models/profile.dart';
import 'package:bitelens_app/data/models/scan_analysis.dart';
import 'package:bitelens_app/data/models/subscription.dart';

void main() {
  group('CalorieCalculator Tests (Mifflin-St Jeor & Rescaling)', () {
    test('Calculates male BMR correctly', () {
      // Male: 10 * 70kg + 6.25 * 175cm - 5 * 25 + 5 = 700 + 1093.75 - 125 + 5 = 1673.75
      final bmr = CalorieCalculator.calculateBmr(
        weightKg: 70,
        heightCm: 175,
        ageYears: 25,
        sex: 'male',
      );
      expect(bmr, closeTo(1673.75, 0.1));
    });

    test('Calculates female BMR correctly', () {
      // Female: 10 * 60kg + 6.25 * 160cm - 5 * 30 - 161 = 600 + 1000 - 150 - 161 = 1289
      final bmr = CalorieCalculator.calculateBmr(
        weightKg: 60,
        heightCm: 160,
        ageYears: 30,
        sex: 'female',
      );
      expect(bmr, closeTo(1289.0, 0.1));
    });

    test('Enforces absolute minimum calorie floor of 1200 kcal', () {
      // Extremely low weight & lose goal would drop below 1200, must be clamped to 1200
      final goal = CalorieCalculator.calculateDailyGoal(
        weightKg: 35,
        heightCm: 130,
        birthYear: 2000,
        sex: 'female',
        activityLevel: 'sedentary',
        goal: 'lose',
        currentYear: 2026,
      );
      expect(goal, equals(1200));
    });

    test('Correctly adjusts goal calories for weight loss (-500) and gain (+300)', () {
      final maintain = CalorieCalculator.calculateDailyGoal(
        weightKg: 70,
        heightCm: 175,
        birthYear: 2000,
        sex: 'male',
        activityLevel: 'moderate', // 1.55
        goal: 'maintain',
        currentYear: 2026,
      );

      final lose = CalorieCalculator.calculateDailyGoal(
        weightKg: 70,
        heightCm: 175,
        birthYear: 2000,
        sex: 'male',
        activityLevel: 'moderate',
        goal: 'lose',
        currentYear: 2026,
      );

      final gain = CalorieCalculator.calculateDailyGoal(
        weightKg: 70,
        heightCm: 175,
        birthYear: 2000,
        sex: 'male',
        activityLevel: 'moderate',
        goal: 'gain',
        currentYear: 2026,
      );

      expect(lose, equals(maintain - 500));
      expect(gain, equals(maintain + 300));
    });

    test('Portion rescaling math scales nutrients proportionally', () {
      // 100g -> 200g (double portion)
      final rescaled = CalorieCalculator.rescaleNutrients(
        originalGrams: 100,
        newGrams: 200,
        calories: 250,
        protein: 15.0,
        carbs: 30.0,
        fat: 8.0,
        fiber: 3.0,
      );

      expect(rescaled['calories'], equals(500.0));
      expect(rescaled['protein_g'], equals(30.0));
      expect(rescaled['carbs_g'], equals(60.0));
      expect(rescaled['fat_g'], equals(16.0));
      expect(rescaled['fiber_g'], equals(6.0));
    });
  });

  group('Model Serialization & Recalculation Tests', () {
    test('Meal recalculateTotals correctly sums items', () {
      const item1 = MealItem(
        name: 'Chicken Biryani',
        portionText: '1 plate',
        gramsEstimate: 350,
        calories: 550,
        proteinG: 32,
        carbsG: 65,
        fatG: 18,
        fiberG: 4,
      );
      const item2 = MealItem(
        name: 'Raita',
        portionText: '1 small bowl',
        gramsEstimate: 100,
        calories: 80,
        proteinG: 3,
        carbsG: 5,
        fatG: 5,
        fiberG: 0,
      );

      final meal = Meal(
        id: 'test-meal-1',
        userId: 'user-123',
        mealType: 'lunch',
        items: [item1, item2],
        totalCalories: 0,
        totalProteinG: 0,
        totalCarbsG: 0,
        totalFatG: 0,
        totalFiberG: 0,
        eatenAt: DateTime.now(),
      );

      final updated = Meal.recalculateTotals(meal);
      expect(updated.totalCalories, equals(630.0));
      expect(updated.totalProteinG, equals(35.0));
      expect(updated.totalCarbsG, equals(70.0));
      expect(updated.totalFatG, equals(23.0));
      expect(updated.totalFiberG, equals(4.0));
    });

    test('Profile fromJson and toJson roundtrip preserves values', () {
      final json = {
        'id': 'profile-abc-123',
        'display_name': 'Rashid',
        'sex': 'male',
        'birth_year': 1998,
        'height_cm': 176.5,
        'weight_kg': 74.0,
        'activity_level': 'active',
        'goal': 'gain',
        'daily_calorie_goal': 2600,
        'units': 'metric',
        'onboarding_done': true,
      };

      final profile = Profile.fromJson(json);
      expect(profile.id, equals('profile-abc-123'));
      expect(profile.displayName, equals('Rashid'));
      expect(profile.dailyCalorieGoal, equals(2600));

      final serialized = profile.toJson();
      expect(serialized['id'], equals('profile-abc-123'));
      expect(serialized['goal'], equals('gain'));
      expect(serialized['onboarding_done'], equals(true));
    });

    test('Subscription isActive logic works for lifetime and expiry', () {
      final activeSub = Subscription(
        userId: 'user-1',
        isPro: true,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(activeSub.isActive, isTrue);

      final expiredSub = Subscription(
        userId: 'user-1',
        isPro: true,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredSub.isActive, isFalse);

      final freeSub = const Subscription(
        userId: 'user-1',
        isPro: false,
      );
      expect(freeSub.isActive, isFalse);
    });

    test('ScanAnalysis parses JSON response correctly', () {
      final json = {
        'is_food': true,
        'dish_summary': 'Chicken Karahi with 2 Tandoori Rotis',
        'confidence': 'high',
        'items': [
          {
            'name': 'Chicken Karahi',
            'portion_text': '1 bowl',
            'grams_estimate': 280,
            'calories': 480,
            'protein_g': 38,
            'carbs_g': 8,
            'fat_g': 32,
            'fiber_g': 2,
          },
        ],
        'total_calories': 480,
        'total_protein_g': 38,
        'total_carbs_g': 8,
        'total_fat_g': 32,
        'total_fiber_g': 2,
      };

      final analysis = ScanAnalysis.fromJson(json);
      expect(analysis.isFood, isTrue);
      expect(analysis.confidence, equals('high'));
      expect(analysis.items.length, equals(1));
      expect(analysis.items.first.name, equals('Chicken Karahi'));
      expect(analysis.totalCalories, equals(480.0));
    });

    test('Formatters format calories and dates cleanly', () {
      expect(Formatters.formatCalories(450.4), equals('450 kcal'));
      expect(Formatters.formatGrams(24.0), equals('24g'));
      expect(Formatters.formatGrams(24.54), equals('24.5g'));
      expect(Formatters.capitalize('breakfast'), equals('Breakfast'));
    });
  });
}
