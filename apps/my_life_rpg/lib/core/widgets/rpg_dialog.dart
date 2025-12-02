import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme.dart';
import 'rpg_button.dart';

class RpgDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions; // 自定义操作按钮列表
  final Color? accentColor;
  final IconData? icon;
  final VoidCallback? onCancel; // 默认取消按钮的回调，不传则不显示默认取消

  const RpgDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.accentColor,
    this.icon,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.accentMain;

    return Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min, // 自适应高度
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: AppSpacing.iconLg),
                  AppSpacing.gapH12,
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.panelHeader.copyWith(
                      color: color,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            AppSpacing.gapV20,

            // 2. Body (Content)
            Flexible(child: child), // 使用 Flexible 防止内容溢出

            AppSpacing.gapV24,

            // 3. Footer (Actions)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onCancel != null) ...[
                  RpgButton(
                    label: "CANCEL",
                    type: RpgButtonType.ghost,
                    onTap: onCancel ?? () => Get.back(),
                  ),
                  if (actions != null) AppSpacing.gapH12,
                ],
                if (actions != null) ...actions!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
