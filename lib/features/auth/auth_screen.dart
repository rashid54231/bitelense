import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/providers/app_providers.dart';

/// Authentication screen supporting Email/Password (Sign In / Sign Up) and Google OAuth.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepoProvider);

      if (_isSignUp) {
        await authRepo.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        );
        if (!mounted) return;
        AppSnackbar.showSuccess(context, 'Account created successfully!');
        context.go('/profile-setup');
      } else {
        await authRepo.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;

        // Sync RevenueCat
        final userId = authRepo.currentUserId;
        if (userId != null) {
          ref.read(subscriptionRepoProvider).logIn(userId);
        }

        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepoProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo mark
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isSignUp ? AppStrings.signUp : AppStrings.signIn,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayMedium(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Join BiteLens to track South Asian & global food intake'
                        : 'Welcome back to your smart nutrition tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Display Name (if sign up)
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.displayName,
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty || !val.contains('@')) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return AppStrings.passwordTooShort;
                      }
                      return null;
                    },
                  ),

                  // Forgot Password
                  if (!_isSignUp) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],

                  // Action Button
                  GradientButton(
                    text: _isSignUp ? AppStrings.signUp : AppStrings.signIn,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppStrings.orDivider,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google Sign In Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: Text(
                      AppStrings.googleSignIn,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitGoogle,
                  ),
                  const SizedBox(height: 28),

                  // Toggle Sign In / Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? AppStrings.alreadyHaveAccount
                            : AppStrings.dontHaveAccount,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp ? AppStrings.signIn : AppStrings.signUp,
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
