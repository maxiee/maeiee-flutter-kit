import 'package:flutter/material.dart';

// 指令组按钮
class RpgIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  const RpgIconButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      tooltip: tooltip,
      constraints: const BoxConstraints(), // 移除默认 padding
      padding: const EdgeInsets.all(8),
      onPressed: onTap,
    );
  }
}
