// lib/core/widgets/rpg_button.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// RPG 风格按钮类型
enum RpgButtonType {
  primary, // 主操作 (橙色)
  secondary, // 次级操作 (青色)
  danger, // 危险操作 (红色)
  ghost, // 幽灵按钮 (透明边框)
}

/// RPG 风格按钮
class RpgButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final RpgButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool compact;

  const RpgButton({
    Key? key,
    required this.label,
    this.onTap,
    this.type = RpgButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.compact = false,
  }) : super(key: key);

  Color get _color {
    switch (type) {
      case RpgButtonType.primary:
        return AppColors.accentMain;
      case RpgButtonType.secondary:
        return AppColors.accentSystem;
      case RpgButtonType.danger:
        return AppColors.accentDanger;
      case RpgButtonType.ghost:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || isLoading;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
          vertical: compact ? 6 : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: type == RpgButtonType.ghost
              ? Colors.transparent
              : _color.withOpacity(isDisabled ? 0.1 : 0.2),
          border: Border.all(color: _color.withOpacity(isDisabled ? 0.3 : 1.0)),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              ),
              AppSpacing.gapH8,
            ] else if (icon != null) ...[
              Icon(icon, size: AppSpacing.iconSm, color: _color),
              AppSpacing.gapH8,
            ],
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: _color.withOpacity(isDisabled ? 0.5 : 1.0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
