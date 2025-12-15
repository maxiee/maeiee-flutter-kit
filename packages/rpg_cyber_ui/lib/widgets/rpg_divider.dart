// lib/core/widgets/rpg_divider.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// RPG 风格分隔线
class RpgDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const RpgDivider({
    Key? key,
    this.height = 1,
    this.thickness = 1,
    this.color,
    this.indent,
    this.endIndent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      color: color ?? AppColors.borderDim,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// RPG 风格垂直分隔线
class RpgVerticalDivider extends StatelessWidget {
  final double width;
  final double thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const RpgVerticalDivider({
    Key? key,
    this.width = 32,
    this.thickness = 1,
    this.color,
    this.indent,
    this.endIndent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: width,
      thickness: thickness,
      color: color ?? AppColors.borderDim,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
