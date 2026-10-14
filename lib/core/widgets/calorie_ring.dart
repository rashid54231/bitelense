import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Animated circular progress ring showing calories eaten vs daily calorie goal.
class CalorieRing extends StatefulWidget {
  final int eaten;
  final int goal;
  final double size;
  final double strokeWidth;

  const CalorieRing({
    super.key,
    required this.eaten,
    required this.goal,
    this.size = 220,
    this.strokeWidth = 16,
  });

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<int> _calorieCountAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final targetProgress = widget.goal > 0
        ? (widget.eaten / widget.goal).clamp(0.0, 1.0)
        : 0.0;

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: targetProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _calorieCountAnimation = IntTween(
      begin: 0,
      end: widget.eaten,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eaten != widget.eaten || oldWidget.goal != widget.goal) {
      final targetProgress = widget.goal > 0
          ? (widget.eaten / widget.goal).clamp(0.0, 1.0)
          : 0.0;

      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: targetProgress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

      _calorieCountAnimation = IntTween(
        begin: _calorieCountAnimation.value,
        end: widget.eaten,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = (widget.goal - widget.eaten).clamp(0, widget.goal);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CalorieRingPainter(
                  progress: _progressAnimation.value,
                  strokeWidth: widget.strokeWidth,
                  trackColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_calorieCountAnimation.value}',
                    style: AppTextStyles.calorieCounter(context),
                  ),
                  Text(
                    'of ${widget.goal} kcal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$remaining kcal left',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;

  _CalorieRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Gradient progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: (3 * math.pi) / 2,
      colors: const [
        AppColors.primaryGreen,
        AppColors.primaryTeal,
        AppColors.primaryLime,
        AppColors.primaryGreen,
      ],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start at top (12 o'clock)
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}
