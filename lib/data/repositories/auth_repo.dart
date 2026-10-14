import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';

/// Repository for authentication and account deletion.
class AuthRepo {
  final SupabaseClient _client;

  AuthRepo(this._client);

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
  bool get isAuthenticated => _client.auth.currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName.trim()} : null,
      );
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Trigger Google OAuth sign-in with deep link redirect
  Future<bool> signInWithGoogle() async {
    try {
      return await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? null
            : 'com.bitelens.app://login-callback',
      );
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Send password reset link to user's email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb
            ? null
            : 'com.bitelens.app://reset-callback',
      );
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Delete account: calls the `delete-account` edge function,
  /// cascades removal of DB rows and storage photos, then signs out.
  Future<void> deleteAccount() async {
    try {
      final res = await _client.functions.invoke('delete-account');
      if (res.status != 200) {
        throw AppException(
          code: 'DELETE_ACCOUNT_FAILED',
          message: 'Failed to delete account. Please try again.',
        );
      }
      await signOut();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }
}
