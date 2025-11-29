// lib/core/widgets/rpg_empty_state.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// RPG 风格空状态占位符
class RpgEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Widget? action;

  const RpgEmptyState({Key? key, required this.message, this.icon, this.action})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: AppColors.textDim),
            AppSpacing.gapV16,
          ],
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textDim),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[AppSpacing.gapV16, action!],
        ],
      ),
    );
  }
}
