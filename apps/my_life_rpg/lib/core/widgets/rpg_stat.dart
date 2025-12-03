import 'package:flutter/material.dart';
import 'package:my_life_rpg/core/widgets/rpg_text.dart';
import '../theme/theme.dart';

/// RPG 风格数据指标展示
/// 样式:
/// VALUE
/// LABEL
class RpgStat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;
  final bool compact;
  final CrossAxisAlignment alignment;

  const RpgStat({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.compact = false,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        // Value Row
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: compact ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              RpgText.micro(unit!, color: AppColors.textDim),
            ],
          ],
        ),
        SizedBox(height: compact ? 0 : 4),
        // Label
        RpgText.micro(label, color: Colors.grey),
      ],
    );
  }
}
