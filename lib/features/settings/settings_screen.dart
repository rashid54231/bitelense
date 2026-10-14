import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers/app_providers.dart';
import '../../data/services/food_ai_service.dart';

/// Settings screen providing account management, unit & theme preferences,
/// subscription management, and account deletion.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {}
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: Env.feedbackEmail,
      queryParameters: {'subject': 'BiteLens Feedback'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.signOut, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(subscriptionRepoProvider).logOut();
      await ref.read(authRepoProvider).signOut();
      if (mounted) context.go('/auth');
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteAccount),
        content: const Text(AppStrings.deleteAccountConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(authRepoProvider).deleteAccount();
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Account deleted successfully.');
          context.go('/auth');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, 'Failed to delete account: $e');
        }
      }
    }
  }

  Future<void> _configureGeminiApiKey() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final currentKey = prefs.getString(FoodAIService.geminiKeyStorageKey) ?? '';
    final controller = TextEditingController(text: currentKey);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primaryGreen, size: 24),
            SizedBox(width: 8),
            Text('Gemini AI Setup', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API Key for direct real-time food and calorie recognition:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
                labelText: 'Gemini API Key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          if (currentKey.isNotEmpty)
            TextButton(
              onPressed: () {
                prefs.remove(FoodAIService.geminiKeyStorageKey);
                Navigator.pop(ctx, true);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                prefs.setString(FoodAIService.geminiKeyStorageKey, newKey);
              } else {
                prefs.remove(FoodAIService.geminiKeyStorageKey);
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final updatedKey = prefs.getString(FoodAIService.geminiKeyStorageKey);
      if (updatedKey != null && updatedKey.isNotEmpty) {
        AppSnackbar.showSuccess(context, 'Gemini API Key saved successfully!');
      } else {
        AppSnackbar.showInfo(context, 'Using smart food recognition.');
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeModeProvider);
    final isPro = ref.watch(isProProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Profile & Goals
            _sectionHeader('Profile & Goals'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: AppColors.primaryGreen),
                title: const Text(AppStrings.editProfile),
                subtitle: const Text('Height, weight, activity & Mifflin-St Jeor target'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/edit-profile'),
              ),
            ),
            const SizedBox(height: 20),

            // Subscription
            _sectionHeader('Subscription'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.stars_rounded, color: AppColors.primaryTeal),
                    title: Text(isPro ? 'BiteLens Pro (Active)' : 'Free Tier (3 scans/day)'),
                    subtitle: Text(isPro ? 'Unlimited food scans & insights' : 'Upgrade to Pro for unlimited scans'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/paywall'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded),
                    title: const Text(AppStrings.restorePurchases),
                    onTap: () async {
                      final active = await ref.read(subscriptionRepoProvider).restorePurchases();
                      if (context.mounted) {
                        if (active) {
                          AppSnackbar.showSuccess(context, 'Purchases restored!');
                          ref.invalidate(isProProvider);
                        } else {
                          AppSnackbar.showInfo(context, 'No active subscription found.');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appearance & Preferences
            _sectionHeader('Preferences'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text(AppStrings.theme),
                    subtitle: Text(currentTheme == ThemeMode.dark
                        ? AppStrings.themeDark
                        : (currentTheme == ThemeMode.light
                            ? AppStrings.themeLight
                            : AppStrings.themeSystem)),
                    trailing: DropdownButton<ThemeMode>(
                      value: currentTheme,
                      underline: const SizedBox.shrink(),
                      dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      items: const [
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome, color: AppColors.primaryGreen),
                    title: const Text('Google Gemini Vision AI'),
                    subtitle: Text(
                      ref.watch(sharedPreferencesProvider).getString(FoodAIService.geminiKeyStorageKey)?.isNotEmpty == true
                          ? 'Active (Custom Gemini Key)'
                          : 'Smart Recognition Active (Tap to set Key)',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _configureGeminiApiKey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Legal & Support
            _sectionHeader('Legal & Support'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text(AppStrings.privacyPolicy),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _openUrl(Env.privacyPolicyUrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text(AppStrings.termsOfService),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _openUrl(Env.termsUrl),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mail_outline_rounded),
                    title: const Text(AppStrings.sendFeedback),
                    onTap: _sendFeedback,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Actions
            _sectionHeader('Account'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                    title: const Text(AppStrings.signOut, style: TextStyle(color: Colors.orange)),
                    onTap: _confirmSignOut,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    title: const Text(AppStrings.deleteAccount, style: TextStyle(color: AppColors.error)),
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Version & Disclaimer Note
            Center(
              child: Column(
                children: [
                  Text(
                    'BiteLens v$_version',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '${AppStrings.disclaimerShort}\n${AppStrings.dataPrivacyNote}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
