import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_compress.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/gradient_button.dart';

/// Screen allowing user to select meal type and trigger camera capture or gallery selection.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedMealType = 'lunch';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = Formatters.suggestMealType();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isProcessing = true);

    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          if (!mounted) return;
          _showPermissionDialog();
          return;
        } else if (!status.isGranted) {
          if (!mounted) return;
          AppSnackbar.showError(context, AppStrings.cameraPermissionRequired);
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return; // user cancelled
      }

      // Compress photo targeting <= 1280px and under 1.5MB
      final compressedFile =
          await ImageCompressUtil.compressMealPhoto(pickedFile.path);

      if (!mounted) return;

      // Navigate to AnalyzingScreen
      context.push(
        '/analyzing',
        extra: {
          'file': compressedFile,
          'meal_type': _selectedMealType,
        },
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to pick image: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'BiteLens needs camera access so you can snap and analyze your food. Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text(AppStrings.openSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanMeal),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Meal Type Picker
              Text(
                AppStrings.selectMealType,
                style: AppTextStyles.titleSmall(context),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _mealTypeChip('breakfast', AppStrings.breakfast, Icons.wb_sunny_outlined),
                  const SizedBox(width: 8),
                  _mealTypeChip('lunch', AppStrings.lunch, Icons.lunch_dining_rounded),
                  const SizedBox(width: 8),
                  _mealTypeChip('dinner', AppStrings.dinner, Icons.nightlife_rounded),
                  const SizedBox(width: 8),
                  _mealTypeChip('snack', AppStrings.snack, Icons.cookie_outlined),
                ],
              ),
              const SizedBox(height: 40),

              // Visual viewfinder frame placeholder
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A22) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.center_focus_strong_rounded,
                            size: 44,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Position plate in center',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Works best with clear lighting on biryani, curries, roti, bowls, snacks & drinks.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              GradientButton(
                text: AppStrings.takePhoto,
                icon: Icons.camera_alt_rounded,
                isLoading: _isProcessing,
                onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 14),

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
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text(
                  AppStrings.chooseFromGallery,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedMealType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMealType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.18)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primaryGreen : Colors.white60,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryGreen : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
