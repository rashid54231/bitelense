import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Pill or compact card displaying a macro nutrient (Protein, Carbs, Fat, Fiber).
class MacroChip extends StatelessWidget {
  final String label;
  final num amountGrams;
  final Color color;
  final IconData? icon;
  final bool showCompact;

  const MacroChip({
    super.key,
    required this.label,
    required this.amountGrams,
    required this.color,
    this.icon,
    this.showCompact = false,
  });

  factory MacroChip.protein(num grams, {bool compact = false}) => MacroChip(
        label: 'Protein',
        amountGrams: grams,
        color: AppColors.proteinColor,
        icon: Icons.fitness_center_rounded,
        showCompact: compact,
      );

  factory MacroChip.carbs(num grams, {bool compact = false}) => MacroChip(
        label: 'Carbs',
        amountGrams: grams,
        color: AppColors.carbsColor,
        icon: Icons.grain_rounded,
        showCompact: compact,
      );

  factory MacroChip.fat(num grams, {bool compact = false}) => MacroChip(
        label: 'Fat',
        amountGrams: grams,
        color: AppColors.fatColor,
        icon: Icons.opacity_rounded,
        showCompact: compact,
      );

  factory MacroChip.fiber(num grams, {bool compact = false}) => MacroChip(
        label: 'Fiber',
        amountGrams: grams,
        color: AppColors.fiberColor,
        icon: Icons.eco_rounded,
        showCompact: compact,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (showCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              Formatters.formatGrams(amountGrams),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatGrams(amountGrams),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
