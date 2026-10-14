import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../models/profile.dart';

/// Repository for managing user profiles and nutritional targets.
class ProfileRepo {
  final SupabaseClient _client;

  ProfileRepo(this._client);

  /// Fetch profile for the authenticated user
  Future<Profile?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;
      return Profile.fromJson(res);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Create or update user profile
  Future<Profile> saveProfile(Profile profile) async {
    try {
      final data = profile.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final res = await _client
          .from('profiles')
          .upsert(data)
          .select()
          .single();

      return Profile.fromJson(res);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding(String userId) async {
    try {
      await _client.from('profiles').update({
        'onboarding_done': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Update daily calorie goal directly
  Future<void> updateDailyGoal(String userId, int goalKcal) async {
    try {
      await _client.from('profiles').update({
        'daily_calorie_goal': goalKcal,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }
}
