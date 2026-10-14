import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal.dart';
import '../models/profile.dart';
import '../repositories/auth_repo.dart';
import '../repositories/meals_repo.dart';
import '../repositories/profile_repo.dart';
import '../repositories/scan_repo.dart';
import '../repositories/subscription_repo.dart';

// ---------------------------------------------------------------------------
// Infrastructure & Repository Providers
// ---------------------------------------------------------------------------

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main');
});

final authRepoProvider = Provider<AuthRepo>((ref) {
  return AuthRepo(ref.watch(supabaseClientProvider));
});

final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo(ref.watch(supabaseClientProvider));
});

final mealsRepoProvider = Provider<MealsRepo>((ref) {
  return MealsRepo(ref.watch(supabaseClientProvider));
});

final scanRepoProvider = Provider<ScanRepo>((ref) {
  return ScanRepo(ref.watch(supabaseClientProvider));
});

final subscriptionRepoProvider = Provider<SubscriptionRepo>((ref) {
  return SubscriptionRepo(ref.watch(supabaseClientProvider));
});

// ---------------------------------------------------------------------------
// Auth State Provider
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepoProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepoProvider).currentUser;
});

// ---------------------------------------------------------------------------
// Profile Provider (AsyncNotifier)
// ---------------------------------------------------------------------------

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return ref.watch(profileRepoProvider).getProfile();
  }

  Future<void> updateProfile(Profile updated) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final saved = await ref.read(profileRepoProvider).saveProfile(updated);
      return saved;
    });
  }

  Future<void> completeOnboarding() async {
    final current = state.value;
    if (current == null) return;
    await ref.read(profileRepoProvider).completeOnboarding(current.id);
    state = AsyncValue.data(current.copyWith(onboardingDone: true));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

// ---------------------------------------------------------------------------
// Today Meals Provider (AsyncNotifier)
// ---------------------------------------------------------------------------

class TodayMealsNotifier extends AsyncNotifier<List<Meal>> {
  @override
  Future<List<Meal>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.watch(mealsRepoProvider).getTodayMeals();
  }

  Future<void> addMeal(Meal meal) async {
    final previous = state.value ?? [];
    // Optimistic insert
    state = AsyncValue.data([meal, ...previous]);

    try {
      final saved = await ref.read(mealsRepoProvider).saveMeal(meal);
      // Replace with saved version
      state = AsyncValue.data([
        saved,
        ...previous.where((m) => m.id != meal.id),
      ]);
      // Also refresh remaining scans
      ref.invalidate(remainingScansProvider);
    } catch (e) {
      // Rollback on failure
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> updateMeal(Meal updated) async {
    final previous = state.value ?? [];
    // Optimistic update
    state = AsyncValue.data(
      previous.map((m) => m.id == updated.id ? updated : m).toList(),
    );

    try {
      final saved = await ref.read(mealsRepoProvider).updateMeal(updated);
      state = AsyncValue.data(
        previous.map((m) => m.id == saved.id ? saved : m).toList(),
      );
    } catch (e) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> deleteMeal(Meal meal) async {
    final previous = state.value ?? [];
    // Optimistic delete
    state = AsyncValue.data(
      previous.where((m) => m.id != meal.id).toList(),
    );

    try {
      await ref.read(mealsRepoProvider).deleteMeal(meal);
    } catch (e) {
      // Rollback
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final todayMealsProvider =
    AsyncNotifierProvider<TodayMealsNotifier, List<Meal>>(TodayMealsNotifier.new);

// ---------------------------------------------------------------------------
// Remaining Daily Scans Provider (AsyncNotifier)
// ---------------------------------------------------------------------------

class RemainingScansNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final isPro = await ref.watch(isProProvider.future);
    if (isPro) return 999; // unlimited
    return ref.watch(scanRepoProvider).getRemainingScansToday();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final remainingScansProvider =
    AsyncNotifierProvider<RemainingScansNotifier, int>(RemainingScansNotifier.new);

// ---------------------------------------------------------------------------
// IsPro Subscription Provider (AsyncNotifier)
// ---------------------------------------------------------------------------

class IsProNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;
    return ref.watch(subscriptionRepoProvider).checkProStatus();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final isProProvider =
    AsyncNotifierProvider<IsProNotifier, bool>(IsProNotifier.new);

// ---------------------------------------------------------------------------
// App Theme Mode Provider (Notifier)
// ---------------------------------------------------------------------------

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themePrefKey = 'user_theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final val = prefs.getString(_themePrefKey) ?? 'dark';
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String val;
    switch (mode) {
      case ThemeMode.light:
        val = 'light';
        break;
      case ThemeMode.system:
        val = 'system';
        break;
      case ThemeMode.dark:
        val = 'dark';
        break;
    }
    await prefs.setString(_themePrefKey, val);
    state = mode;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
