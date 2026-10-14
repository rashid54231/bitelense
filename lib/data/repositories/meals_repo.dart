import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../models/meal.dart';

/// Repository for meal entries and private storage signed URLs.
class MealsRepo {
  final SupabaseClient _client;

  // In-memory cache for signed URLs to minimize Supabase storage requests: path -> (url, expiry)
  final Map<String, ({String url, DateTime expiresAt})> _signedUrlCache = {};

  MealsRepo(this._client);

  /// Fetch meals for today for the authenticated user
  Future<List<Meal>> getTodayMeals() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay =
          DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final res = await _client
          .from('meals')
          .select()
          .eq('user_id', userId)
          .gte('eaten_at', startOfDay)
          .lte('eaten_at', endOfDay)
          .order('eaten_at', ascending: false);

      return (res as List)
          .map((m) => Meal.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Fetch meals for a specific date range
  Future<List<Meal>> getMealsForRange({
    required DateTime start,
    required DateTime end,
    bool isPro = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // If not Pro, restrict query to at most the last 3 days
      DateTime effectiveStart = start;
      if (!isPro) {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        if (effectiveStart.isBefore(threeDaysAgo)) {
          effectiveStart = threeDaysAgo;
        }
      }

      final res = await _client
          .from('meals')
          .select()
          .eq('user_id', userId)
          .gte('eaten_at', effectiveStart.toIso8601String())
          .lte('eaten_at', end.toIso8601String())
          .order('eaten_at', ascending: false);

      return (res as List)
          .map((m) => Meal.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Insert a new meal into the database
  Future<Meal> saveMeal(Meal meal) async {
    try {
      final data = meal.toJson();
      // Remove id if it's empty so gen_random_uuid() is used
      if (meal.id.isEmpty) {
        data.remove('id');
      }

      final res = await _client.from('meals').insert(data).select().single();
      return Meal.fromJson(res);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Update an existing meal
  Future<Meal> updateMeal(Meal meal) async {
    try {
      final data = meal.toJson();
      data['user_edited'] = true;

      final res = await _client
          .from('meals')
          .update(data)
          .eq('id', meal.id)
          .select()
          .single();

      return Meal.fromJson(res);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Delete a meal from the database and remove its photo from storage
  Future<void> deleteMeal(Meal meal) async {
    try {
      await _client.from('meals').delete().eq('id', meal.id);

      if (meal.imagePath != null && meal.imagePath!.isNotEmpty) {
        await deletePhoto(meal.imagePath!);
      }
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Delete a photo from the `meal-photos` storage bucket
  Future<void> deletePhoto(String path) async {
    try {
      await _client.storage.from('meal-photos').remove([path]);
      _signedUrlCache.remove(path);
    } catch (e) {
      debugPrint('Warning: Failed to delete storage photo $path: $e');
    }
  }

  /// Get a cached signed URL for a photo in the private `meal-photos` bucket
  Future<String?> getSignedImageUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;

    // Check memory cache
    final cached = _signedUrlCache[storagePath];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.url;
    }

    try {
      // 1 hour validity (3600 seconds)
      const expiresIn = 3600;
      final signedUrl = await _client.storage
          .from('meal-photos')
          .createSignedUrl(storagePath, expiresIn);

      _signedUrlCache[storagePath] = (
        url: signedUrl,
        expiresAt: DateTime.now().add(const Duration(seconds: expiresIn - 60)),
      );

      return signedUrl;
    } catch (e) {
      debugPrint('Error getting signed URL for $storagePath: $e');
      return null;
    }
  }
}
