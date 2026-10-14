/// Nutritional item within an analyzed meal.
class MealItem {
  final String name;
  final String portionText;
  final double gramsEstimate;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const MealItem({
    required this.name,
    required this.portionText,
    required this.gramsEstimate,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  MealItem copyWith({
    String? name,
    String? portionText,
    double? gramsEstimate,
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
  }) {
    return MealItem(
      name: name ?? this.name,
      portionText: portionText ?? this.portionText,
      gramsEstimate: gramsEstimate ?? this.gramsEstimate,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
    );
  }

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      name: json['name'] as String? ?? 'Unknown dish',
      portionText: json['portion_text'] as String? ?? '1 serving',
      gramsEstimate: (json['grams_estimate'] as num?)?.toDouble() ?? 100.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'portion_text': portionText,
      'grams_estimate': gramsEstimate,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
    };
  }
}
