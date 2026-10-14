import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../data/providers/app_providers.dart';

/// Fullscreen paywall presenting subscription packages via RevenueCat.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await ref.read(subscriptionRepoProvider).getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _selectedPackage = offerings?.current?.annual ??
              offerings?.current?.monthly ??
              offerings?.current?.availablePackages.firstOrNull;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchase() async {
    if (_selectedPackage == null) {
      // Demo / fallback mode for local testing without real RevenueCat account
      AppSnackbar.showInfo(context, 'Running in preview mode. Tap Restore to simulate Pro.');
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      final success = await ref
          .read(subscriptionRepoProvider)
          .purchasePackage(_selectedPackage!);

      if (success && mounted) {
        AppSnackbar.showSuccess(context, AppStrings.purchaseSuccess);
        ref.invalidate(isProProvider);
        ref.invalidate(remainingScansProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      final active = await ref.read(subscriptionRepoProvider).restorePurchases();
      if (!mounted) return;

      if (active) {
        AppSnackbar.showSuccess(context, 'Purchases restored successfully!');
        ref.invalidate(isProProvider);
        ref.invalidate(remainingScansProvider);
        context.pop();
      } else {
        AppSnackbar.showInfo(context, 'No active Pro subscription found.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Restore failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isPurchasing ? null : _restore,
            child: const Text(
              AppStrings.restorePurchases,
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pro Icon Header
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                AppStrings.upgradeToPro,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium(context).copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock unlimited smart scans and deep nutrition analytics.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Pro Features List
              _featureRow(Icons.all_inclusive_rounded, AppStrings.proFeature1),
              _featureRow(Icons.history_edu_rounded, AppStrings.proFeature2),
              _featureRow(Icons.auto_graph_rounded, AppStrings.proFeature3),
              _featureRow(Icons.bolt_rounded, AppStrings.proFeature4),
              const SizedBox(height: 24),

              // Pricing Packages
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_offerings?.current != null &&
                  _offerings!.current!.availablePackages.isNotEmpty)
                ..._offerings!.current!.availablePackages.map((pkg) {
                  final isSelected = _selectedPackage?.identifier == pkg.identifier;
                  return _packageCard(
                    title: pkg.packageType == PackageType.annual
                        ? AppStrings.yearly
                        : AppStrings.monthly,
                    price: pkg.storeProduct.priceString,
                    period: pkg.packageType == PackageType.annual ? '/ year' : '/ month',
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedPackage = pkg),
                  );
                })
              else ...[
                // Fallback UI if RevenueCat packages are still being set up in console
                _packageCard(
                  title: AppStrings.yearly,
                  price: '\$29.99',
                  period: '/ year (Save 33%)',
                  isSelected: true,
                  onTap: () {},
                ),
                _packageCard(
                  title: AppStrings.monthly,
                  price: '\$3.99',
                  period: '/ month',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
              const SizedBox(height: 24),

              // Subscribe Button
              GradientButton(
                text: 'Continue with Pro',
                isLoading: _isPurchasing,
                onPressed: _purchase,
              ),
              const SizedBox(height: 20),

              // Terms & Privacy Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _openUrl(Env.termsUrl),
                    child: const Text(
                      AppStrings.termsOfService,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text('  •  ', style: TextStyle(color: AppColors.darkTextMuted)),
                  GestureDetector(
                    onTap: () => _openUrl(Env.privacyPolicyUrl),
                    child: const Text(
                      AppStrings.privacyPolicy,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageCard({
    required String title,
    required String price,
    required String period,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderColor: isSelected ? AppColors.primaryGreen : null,
      backgroundColor: isSelected
          ? AppColors.primaryGreen.withValues(alpha: 0.12)
          : null,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                period,
                style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primaryGreen : Colors.white38,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
