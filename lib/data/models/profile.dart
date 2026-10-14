/// User profile data reflecting the `profiles` table in Supabase.
class Profile {
  final String id;
  final String? displayName;
  final String sex; // 'male', 'female', 'other'
  final int birthYear;
  final double heightCm;
  final double weightKg;
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final String goal; // 'lose', 'maintain', 'gain'
  final int dailyCalorieGoal;
  final String units; // 'metric', 'imperial'
  final bool onboardingDone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.displayName,
    this.sex = 'other',
    this.birthYear = 1995,
    this.heightCm = 170.0,
    this.weightKg = 70.0,
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
    this.dailyCalorieGoal = 2000,
    this.units = 'metric',
    this.onboardingDone = false,
    this.createdAt,
    this.updatedAt,
  });

  Profile copyWith({
    String? id,
    String? displayName,
    String? sex,
    int? birthYear,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? goal,
    int? dailyCalorieGoal,
    String? units,
    bool? onboardingDone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      units: units ?? this.units,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      sex: json['sex'] as String? ?? 'other',
      birthYear: (json['birth_year'] as num?)?.toInt() ?? 1995,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 170.0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 70.0,
      activityLevel: json['activity_level'] as String? ?? 'moderate',
      goal: json['goal'] as String? ?? 'maintain',
      dailyCalorieGoal: (json['daily_calorie_goal'] as num?)?.toInt() ?? 2000,
      units: json['units'] as String? ?? 'metric',
      onboardingDone: json['onboarding_done'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'sex': sex,
      'birth_year': birthYear,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel,
      'goal': goal,
      'daily_calorie_goal': dailyCalorieGoal,
      'units': units,
      'onboarding_done': onboardingDone,
    };
  }
}
