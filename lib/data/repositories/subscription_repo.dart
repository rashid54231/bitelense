import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env.dart';
import '../../core/errors/app_exception.dart';
import '../models/subscription.dart';

/// Repository for in-app subscriptions via RevenueCat and Supabase verification.
class SubscriptionRepo {
  final SupabaseClient _supabaseClient;
  bool _isConfigured = false;

  SubscriptionRepo(this._supabaseClient);

  /// Initialize RevenueCat SDK with the appropriate platform public API key
  Future<void> init() async {
    if (kIsWeb) return;

    try {
      final apiKey = Platform.isAndroid
          ? Env.revenuecatAndroidKey
          : Env.revenuecatIosKey;

      if (apiKey.isEmpty || apiKey.contains('placeholder')) {
        debugPrint('RevenueCat: using placeholder key, SDK running in demo mode');
        return;
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));
      _isConfigured = true;
    } catch (e) {
      debugPrint('Error configuring RevenueCat: $e');
    }
  }

  /// Sync RevenueCat identity with Supabase user ID
  Future<void> logIn(String userId) async {
    if (!_isConfigured) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('Error logging in to RevenueCat: $e');
    }
  }

  /// Log out from RevenueCat when user signs out
  Future<void> logOut() async {
    if (!_isConfigured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Error logging out of RevenueCat: $e');
    }
  }

  /// Check Pro status combining RevenueCat client entitlement with server row
  Future<bool> checkProStatus() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    // 1. Check local RevenueCat entitlement for immediate UI response
    if (_isConfigured) {
      try {
        final customerInfo = await Purchases.getCustomerInfo();
        if (customerInfo.entitlements.all['pro']?.isActive ?? false) {
          return true;
        }
      } catch (e) {
        debugPrint('Error checking RevenueCat customer info: $e');
      }
    }

    // 2. Check Supabase server subscriptions table (source of truth)
    try {
      final serverSub = await getServerSubscription(userId);
      if (serverSub != null && serverSub.isActive) {
        return true;
      }
    } catch (e) {
      debugPrint('Error checking Supabase subscription: $e');
    }

    return false;
  }

  /// Fetch subscription record from Supabase `subscriptions` table
  Future<Subscription?> getServerSubscription(String userId) async {
    try {
      final res = await _supabaseClient
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      return Subscription.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching server subscription: $e');
      return null;
    }
  }

  /// Fetch available offerings (monthly, annual)
  Future<Offerings?> getOfferings() async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error fetching RevenueCat offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!_isConfigured) {
      throw const AppException(
        code: 'RC_NOT_CONFIGURED',
        message: 'In-app purchases are not configured for this build.',
      );
    }

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all['pro']?.isActive ?? false;
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('cancelled') || str.contains('canceled') || str.contains('1')) {
        throw const AppException(
          code: 'PURCHASE_CANCELLED',
          message: 'Purchase was cancelled.',
        );
      }
      throw AppException.fromError(e);
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_isConfigured) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['pro']?.isActive ?? false;
    } catch (e) {
      throw AppException.fromError(e);
    }
  }
}
