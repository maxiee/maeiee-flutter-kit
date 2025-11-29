// lib/core/widgets/rpg_panel_header.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// RPG 风格面板头部
class RpgPanelHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  const RpgPanelHeader({
    Key? key,
    required this.title,
    this.actions,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.paddingSm,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(title, style: AppTextStyles.panelHeader),
          ),
          if (actions != null)
            Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ],
      ),
    );
  }
}

/// HUD 数据块（用于显示统计数据）
class RpgStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color? valueColor;
  final String? subtitle;
  final CrossAxisAlignment alignment;

  const RpgStatBlock({
    Key? key,
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor,
    this.subtitle,
    this.alignment = CrossAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapV4,
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.accentSystem,
                fontSize: 24,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            if (suffix != null) ...[
              AppSpacing.gapH4,
              Text(
                suffix!,
                style: TextStyle(
                  color: (valueColor ?? AppColors.accentSystem).withOpacity(
                    0.5,
                  ),
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          AppSpacing.gapV4,
          Text(
            subtitle!,
            style: AppTextStyles.caption.copyWith(color: AppColors.textDim),
          ),
        ],
      ],
    );
  }
}

/// HUD 倒计时块
class RpgCountdown extends StatelessWidget {
  final String label;
  final String time;
  final String? target;
  final Color? color;

  const RpgCountdown({
    Key? key,
    required this.label,
    required this.time,
    this.target,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppColors.accentMain;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapV4,
        Text(
          time,
          style: TextStyle(
            color: displayColor,
            fontSize: 20,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        if (target != null) ...[
          AppSpacing.gapV4,
          Text(
            target!,
            style: AppTextStyles.caption.copyWith(color: AppColors.textDim),
          ),
        ],
      ],
    );
  }
}
