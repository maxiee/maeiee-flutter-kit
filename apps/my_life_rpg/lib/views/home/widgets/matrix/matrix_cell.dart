import 'package:flutter/material.dart';

class MatrixCell extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String? tooltip;

  // 保留布局属性
  final bool isSelected;
  final VoidCallback onTap;

  // 辅助布局属性 (用于圆角计算，这部分属于 UI 逻辑，可以保留，也可以由父级传 Radius)
  // 为了保持改动最小且合理，我们保留这部分 UI 逻辑，但把数据逻辑移走
  final bool isLeftConnected;
  final bool isRightConnected;
  final bool isRowStart;
  final bool isRowEnd;

  const MatrixCell({
    super.key,
    required this.color,
    required this.borderColor,
    this.tooltip,
    required this.isSelected,
    required this.isLeftConnected,
    required this.isRightConnected,
    required this.isRowStart,
    required this.isRowEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 样式微调
    Color finalBorderColor = borderColor;
    if (isSelected) finalBorderColor = Colors.white;

    // 2. 形状计算
    BorderRadius radius;
    radius = BorderRadius.horizontal(
      left: (isLeftConnected && !isRowStart)
          ? Radius.zero
          : const Radius.circular(2),
      right: (isRightConnected && !isRowEnd)
          ? Radius.zero
          : const Radius.circular(2),
    );

    // 3. 渲染
    // [修改]: 移除内部 Text，包裹 Tooltip
    return Tooltip(
      message: tooltip ?? "",
      triggerMode: tooltip != null ? TooltipTriggerMode.longPress : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(color: finalBorderColor),
          ),
        ),
      ),
    );
  }
}
