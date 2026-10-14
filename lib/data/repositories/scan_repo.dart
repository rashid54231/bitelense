import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../models/scan_analysis.dart';
import '../services/food_ai_service.dart';

/// Repository for uploading food photos and calling the `analyze-meal` Edge Function
/// with automatic direct Gemini Vision / smart analyzer fallback.
class ScanRepo {
  final SupabaseClient _client;
  final SharedPreferences _prefs;

  ScanRepo(this._client, this._prefs);

  static const int freeDailyLimit = 3;

  /// Check remaining scans for today for a free user
  Future<int> getRemainingScansToday() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return freeDailyLimit;

    try {
      final todayStr = Formatters.toIsoDate(DateTime.now());
      final res = await _client
          .from('daily_usage')
          .select('scan_count')
          .eq('user_id', userId)
          .eq('usage_date', todayStr)
          .maybeSingle();

      if (res == null) return freeDailyLimit;
      final count = (res['scan_count'] as num?)?.toInt() ?? 0;
      final remaining = freeDailyLimit - count;
      return remaining < 0 ? 0 : remaining;
    } catch (e) {
      debugPrint('Error getting remaining scans: $e');
      return freeDailyLimit;
    }
  }

  /// Uploads photo to `meal-photos/{userId}/{uuid}.jpg`
  Future<String> uploadMealPhoto({
    required File file,
    required String photoUuid,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException(
        code: 'AUTH_REQUIRED',
        message: 'You must be signed in to upload food photos.',
      );
    }

    final path = '$userId/$photoUuid.jpg';

    try {
      final bytes = await file.readAsBytes();
      await _client.storage.from('meal-photos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return path;
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Analyzes food photo via Supabase Edge Function with seamless direct Gemini Vision fallback.
  Future<ScanAnalysis> analyzeMeal({
    required String imagePath,
    required String mealType,
    File? localFile,
  }) async {
    // 1. Attempt Supabase Edge Function first if deployed
    try {
      final tzName = DateTime.now().timeZoneName;

      final response = await _client.functions.invoke(
        'analyze-meal',
        body: {
          'image_path': imagePath,
          'meal_type': mealType,
          'tz': tzName,
        },
      );

      final status = response.status;
      final data = response.data;

      if (status == 429 || (data is Map && data['error']?['code'] == 'LIMIT_REACHED')) {
        await deleteUploadedPhoto(imagePath);
        throw const AppException(
          code: 'LIMIT_REACHED',
          message:
              'You have used all 3 free scans for today. Upgrade to Pro for unlimited scanning!',
        );
      }

      if (status == 200 && data != null) {
        final payload = Map<String, dynamic>.from(data as Map);
        final analysisData = payload['data'] != null
            ? Map<String, dynamic>.from(payload['data'] as Map)
            : payload;

        final isFood = analysisData['is_food'] as bool? ?? true;
        if (!isFood) {
          await deleteUploadedPhoto(imagePath);
          throw const AppException(
            code: 'NOT_FOOD',
            message:
                'We could not recognize any food in this photo. This scan did not count against your limit.',
          );
        }

        return ScanAnalysis.fromJson(
          analysisData,
          imagePath: imagePath,
          mealType: mealType,
        );
      }
    } catch (e) {
      if (e is AppException && (e.code == 'LIMIT_REACHED' || e.code == 'NOT_FOOD')) {
        rethrow;
      }
      debugPrint('Edge function unavailable ($e). Falling back to Direct AI Analyzer...');
    }

    // 2. Direct AI Service fallback (runs Gemini Vision direct or smart analyzer)
    try {
      final aiService = FoodAIService(_prefs);
      return await aiService.analyzeFood(
        localFile: localFile,
        imagePath: imagePath,
        mealType: mealType,
      );
    } catch (e) {
      debugPrint('Direct AI Service error: $e');
      throw AppException.fromError(e);
    }
  }

  /// Deletes photo if user cancels/discards
  Future<void> deleteUploadedPhoto(String imagePath) async {
    try {
      await _client.storage.from('meal-photos').remove([imagePath]);
    } catch (e) {
      debugPrint('Warning: Could not remove uploaded photo $imagePath: $e');
    }
  }
}
