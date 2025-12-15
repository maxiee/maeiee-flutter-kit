import 'package:flutter/material.dart';
import '../theme/theme.dart';

class RpgText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color? color;
  final int? maxLines;
  final bool overflow;

  const RpgText(
    this.text, {
    super.key,
    required this.style,
    this.color,
    this.maxLines,
    this.overflow = false,
  });

  // 快捷构造函数
  const RpgText.hero(this.text, {super.key, this.color})
    : style = AppTextStyles.heroNumber,
      maxLines = 1,
      overflow = false;
  const RpgText.header(this.text, {super.key, this.color})
    : style = AppTextStyles.panelHeader,
      maxLines = 1,
      overflow = true;
  const RpgText.body(this.text, {super.key, this.color, this.maxLines})
    : style = AppTextStyles.body,
      overflow = true;
  const RpgText.caption(this.text, {super.key, this.color})
    : style = AppTextStyles.caption,
      maxLines = 1,
      overflow = true;
  const RpgText.micro(this.text, {super.key, this.color})
    : style = AppTextStyles.micro,
      maxLines = 1,
      overflow = false;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: color != null ? style.copyWith(color: color) : style,
      maxLines: maxLines,
      overflow: overflow ? TextOverflow.ellipsis : null,
    );
  }
}
