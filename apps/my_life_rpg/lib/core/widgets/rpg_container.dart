import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum RpgContainerStyle {
  panel, // 深色背景，带边框 (默认面板)
  card, // 稍亮背景 (卡片)
  outline, // 仅边框 (装饰性)
  glass, // 半透明 (HUD)
}

class RpgContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final RpgContainerStyle style;
  final Color? overrideColor; // 特殊情况覆盖颜色
  final bool focused; // 是否高亮/选中/发光

  const RpgContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.style = RpgContainerStyle.panel,
    this.overrideColor,
    this.focused = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 样式解析
    Color bgColor;
    Color borderColor;
    double borderWidth = 1.0;

    switch (style) {
      case RpgContainerStyle.panel:
        bgColor = AppColors.bgPanel;
        borderColor = AppColors.borderDim;
        break;
      case RpgContainerStyle.card:
        bgColor = AppColors.bgCard;
        borderColor = AppColors.borderDim;
        break;
      case RpgContainerStyle.outline:
        bgColor = Colors.transparent;
        borderColor = AppColors.borderDim;
        break;
      case RpgContainerStyle.glass:
        bgColor = Colors.black.withOpacity(0.3);
        borderColor = Colors.white10;
        break;
    }

    // 2. 状态覆盖
    if (focused) {
      borderColor = AppColors.accentMain;
      if (style == RpgContainerStyle.card) {
        bgColor = AppColors.accentMain.withOpacity(0.1);
      }
      borderWidth = 1.5;
    }

    if (overrideColor != null) {
      borderColor = overrideColor!;
      if (focused) {
        bgColor = overrideColor!.withOpacity(0.15);
      }
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(focused ? 4 : 8), // 选中时更锐利
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: (overrideColor ?? AppColors.accentMain).withOpacity(
                    0.2,
                  ),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
