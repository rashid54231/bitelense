import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/error_state.dart';
import '../../data/providers/app_providers.dart';

/// Screen displayed while uploading food photo and analyzing with Gemini AI via Edge Function.
class AnalyzingScreen extends ConsumerStatefulWidget {
  final File file;
  final String mealType;

  const AnalyzingScreen({
    super.key,
    required this.file,
    required this.mealType,
  });

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  Timer? _statusTimer;
  Timer? _timeoutTimer;
  int _statusIndex = 0;
  bool _isCancelled = false;
  String? _uploadedPath;

  String? _errorMessage;
  bool _isNotFood = false;

  final List<String> _statusTexts = [
    AppStrings.analyzingSubtext1,
    AppStrings.analyzingSubtext2,
    AppStrings.analyzingSubtext3,
  ];

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Rotate status messages every 2.5s
    _statusTimer = Timer.periodic(const Duration(milliseconds: 2500), (t) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusTexts.length;
        });
      }
    });

    // 45s analysis timeout
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && _errorMessage == null) {
        setState(() {
          _errorMessage = AppStrings.timeoutError;
        });
      }
    });

    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    final scanRepo = ref.read(scanRepoProvider);
    final photoUuid = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // 1. Upload photo to private storage bucket
      final path = await scanRepo.uploadMealPhoto(
        file: widget.file,
        photoUuid: photoUuid,
      );
      _uploadedPath = path;

      if (_isCancelled) {
        await scanRepo.deleteUploadedPhoto(path);
        return;
      }

      // 2. Call analyze-meal edge function with direct Gemini Vision fallback
      final analysis = await scanRepo.analyzeMeal(
        imagePath: path,
        mealType: widget.mealType,
        localFile: widget.file,
      );

      if (_isCancelled) {
        await scanRepo.deleteUploadedPhoto(path);
        return;
      }

      // Analysis complete: navigate to ResultScreen
      if (!mounted) return;
      _timeoutTimer?.cancel();

      context.pushReplacement(
        '/result',
        extra: {
          'analysis': analysis,
          'image_path': path,
          'local_file': widget.file,
        },
      );
    } catch (e) {
      if (_isCancelled || !mounted) return;

      final appErr = AppException.fromError(e);

      if (appErr.code == 'LIMIT_REACHED') {
        // Redirect to paywall directly
        context.pushReplacement('/paywall');
        return;
      }

      setState(() {
        _isNotFood = appErr.code == 'NOT_FOOD';
        _errorMessage = appErr.message;
      });
    }
  }

  Future<void> _cancel() async {
    _isCancelled = true;
    _timeoutTimer?.cancel();
    _statusTimer?.cancel();

    if (_uploadedPath != null) {
      await ref.read(scanRepoProvider).deleteUploadedPhoto(_uploadedPath!);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ErrorState(
                icon: _isNotFood
                    ? Icons.no_food_rounded
                    : Icons.error_outline_rounded,
                message: _errorMessage!,
                onRetry: _isNotFood
                    ? null
                    : () {
                        setState(() {
                          _errorMessage = null;
                        });
                        _startAnalysis();
                      },
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Back to Camera'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              AppStrings.analyzing,
              style: AppTextStyles.titleLarge(context).copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _statusTexts[_statusIndex],
                key: ValueKey<int>(_statusIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Scanning Viewfinder with Laser Line
            Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  height: 380,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image Preview
                        Image.file(
                          widget.file,
                          fit: BoxFit.cover,
                        ),

                        // Dark tint overlay
                        Container(color: Colors.black.withValues(alpha: 0.2)),

                        // Animated scanning laser line
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(
                                0.0,
                                -1.0 + (_scanAnimation.value * 2.0),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primaryGreen,
                                      AppColors.primaryTeal,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextButton.icon(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                label: const Text(
                  AppStrings.cancel,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _cancel,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
