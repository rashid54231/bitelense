import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Glassmorphism card with backdrop blur, 20px border radius, and 1px border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.75)
        : AppColors.lightSurface.withValues(alpha: 0.85);
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final cardWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: onTap != null
            ? InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: onTap,
                child: cardWidget,
              )
            : cardWidget,
      );
    }

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
