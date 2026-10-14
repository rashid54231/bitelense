import 'meal_item.dart';

/// Response payload from the `analyze-meal` Supabase Edge Function.
class ScanAnalysis {
  final bool isFood;
  final String dishSummary;
  final String confidence; // 'high', 'medium', 'low'
  final List<MealItem> items;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;
  final String? imagePath;
  final String mealType;

  const ScanAnalysis({
    required this.isFood,
    this.dishSummary = '',
    this.confidence = 'medium',
    required this.items,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
    this.imagePath,
    this.mealType = 'lunch',
  });

  ScanAnalysis copyWith({
    bool? isFood,
    String? dishSummary,
    String? confidence,
    List<MealItem>? items,
    double? totalCalories,
    double? totalProteinG,
    double? totalCarbsG,
    double? totalFatG,
    double? totalFiberG,
    String? imagePath,
    String? mealType,
  }) {
    return ScanAnalysis(
      isFood: isFood ?? this.isFood,
      dishSummary: dishSummary ?? this.dishSummary,
      confidence: confidence ?? this.confidence,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteinG: totalProteinG ?? this.totalProteinG,
      totalCarbsG: totalCarbsG ?? this.totalCarbsG,
      totalFatG: totalFatG ?? this.totalFatG,
      totalFiberG: totalFiberG ?? this.totalFiberG,
      imagePath: imagePath ?? this.imagePath,
      mealType: mealType ?? this.mealType,
    );
  }

  factory ScanAnalysis.fromJson(Map<String, dynamic> json, {String? imagePath, String? mealType}) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => MealItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return ScanAnalysis(
      isFood: json['is_food'] as bool? ?? true,
      dishSummary: json['dish_summary'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'medium',
      items: itemsList,
      totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0.0,
      totalProteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0.0,
      totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0.0,
      totalFatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0.0,
      totalFiberG: (json['total_fiber_g'] as num?)?.toDouble() ?? 0.0,
      imagePath: imagePath ?? json['image_path'] as String?,
      mealType: mealType ?? json['meal_type'] as String? ?? 'lunch',
    );
  }

  /// Recalculates total nutrients based on current items list
  ScanAnalysis recalculateTotals() {
    double cal = 0;
    double p = 0;
    double c = 0;
    double f = 0;
    double fib = 0;

    for (final item in items) {
      cal += item.calories;
      p += item.proteinG;
      c += item.carbsG;
      f += item.fatG;
      fib += item.fiberG;
    }

    return copyWith(
      totalCalories: cal.roundToDouble(),
      totalProteinG: (p * 10).round() / 10.0,
      totalCarbsG: (c * 10).round() / 10.0,
      totalFatG: (f * 10).round() / 10.0,
      totalFiberG: (fib * 10).round() / 10.0,
    );
  }
}
