import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// 标准面板容器
class RpgContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool withBorder;

  const RpgContainer({
    Key? key,
    required this.child,
    this.padding,
    this.color,
    this.withBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.bgPanel,
        borderRadius: BorderRadius.circular(8), // 统一 8px
        border: withBorder ? Border.all(color: AppColors.borderDim) : null,
      ),
      child: child,
    );
  }
}
