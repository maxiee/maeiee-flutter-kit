import 'package:flutter/material.dart';

import '../theme/theme.dart';

class RpgFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  const RpgFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppColors.accentMain;
    final activeColor = selected ? displayColor : Colors.grey;
    final bgColor = selected
        ? displayColor.withOpacity(0.1)
        : Colors.transparent;
    final borderColor = selected
        ? displayColor
        : Colors.transparent; // 未选中无边框，或者是极淡边框

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: activeColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.micro.copyWith(
                color: activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 保留原有的 RpgMacroChip (如果还在用)

/// 宏命令芯片（用于 Session 页面的快捷输入）
class RpgMacroChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const RpgMacroChip({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
  });

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
