import 'meal_item.dart';

/// Meal entity corresponding to the `meals` table in Supabase.
class Meal {
  final String id;
  final String userId;
  final String? imagePath;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final List<MealItem> items;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final double totalFiberG;
  final String confidence; // 'high', 'medium', 'low'
  final bool userEdited;
  final DateTime eatenAt;
  final DateTime? createdAt;

  const Meal({
    required this.id,
    required this.userId,
    this.imagePath,
    required this.mealType,
    required this.items,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.totalFiberG,
    this.confidence = 'medium',
    this.userEdited = false,
    required this.eatenAt,
    this.createdAt,
  });

  Meal copyWith({
    String? id,
    String? userId,
    String? imagePath,
    String? mealType,
    List<MealItem>? items,
    double? totalCalories,
    double? totalProteinG,
    double? totalCarbsG,
    double? totalFatG,
    double? totalFiberG,
    String? confidence,
    bool? userEdited,
    DateTime? eatenAt,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      mealType: mealType ?? this.mealType,
      items: items ?? this.items,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProteinG: totalProteinG ?? this.totalProteinG,
      totalCarbsG: totalCarbsG ?? this.totalCarbsG,
      totalFatG: totalFatG ?? this.totalFatG,
      totalFiberG: totalFiberG ?? this.totalFiberG,
      confidence: confidence ?? this.confidence,
      userEdited: userEdited ?? this.userEdited,
      eatenAt: eatenAt ?? this.eatenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => MealItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return Meal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imagePath: json['image_path'] as String?,
      mealType: json['meal_type'] as String? ?? 'lunch',
      items: itemsList,
      totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0.0,
      totalProteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0.0,
      totalCarbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0.0,
      totalFatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0.0,
      totalFiberG: (json['total_fiber_g'] as num?)?.toDouble() ?? 0.0,
      confidence: json['confidence'] as String? ?? 'medium',
      userEdited: json['user_edited'] as bool? ?? false,
      eatenAt: json['eaten_at'] != null
          ? DateTime.parse(json['eaten_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_path': imagePath,
      'meal_type': mealType,
      'items': items.map((i) => i.toJson()).toList(),
      'total_calories': totalCalories,
      'total_protein_g': totalProteinG,
      'total_carbs_g': totalCarbsG,
      'total_fat_g': totalFatG,
      'total_fiber_g': totalFiberG,
      'confidence': confidence,
      'user_edited': userEdited,
      'eaten_at': eatenAt.toIso8601String(),
    };
  }

  /// Helper to recompute totals from items
  static Meal recalculateTotals(Meal meal) {
    double cal = 0;
    double p = 0;
    double c = 0;
    double f = 0;
    double fib = 0;

    for (final item in meal.items) {
      cal += item.calories;
      p += item.proteinG;
      c += item.carbsG;
      f += item.fatG;
      fib += item.fiberG;
    }

    return meal.copyWith(
      totalCalories: cal.roundToDouble(),
      totalProteinG: (p * 10).round() / 10.0,
      totalCarbsG: (c * 10).round() / 10.0,
      totalFatG: (f * 10).round() / 10.0,
      totalFiberG: (fib * 10).round() / 10.0,
    );
  }
}
