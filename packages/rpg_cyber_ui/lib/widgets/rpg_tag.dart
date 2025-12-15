import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

// 高频使用的标签
class RpgTag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const RpgTag({Key? key, required this.label, required this.color, this.icon})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(2), // 锐利圆角
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.micro.copyWith(color: color, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
