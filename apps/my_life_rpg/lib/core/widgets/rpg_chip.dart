// lib/core/widgets/rpg_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// RPG 风格选择芯片（用于过滤器、多选等）
class RpgChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? activeColor;

  const RpgChip({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.accentSystem;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isSelected ? Colors.black : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 宏命令芯片（用于 Session 页面的快捷输入）
class RpgMacroChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const RpgMacroChip({
    Key? key,
    required this.label,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
