// lib/core/widgets/rpg_input.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// RPG 风格输入框
class RpgInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Color? accentColor;
  final bool autofocus;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const RpgInput({
    Key? key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.accentColor,
    this.autofocus = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.accentMain;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      style: AppTextStyles.body,
      cursorColor: AppColors.accentSafe,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption.copyWith(color: Colors.grey),
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: Colors.white24),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: AppSpacing.iconMd, color: color)
            : null,
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding: AppSpacing.paddingMd,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderBright),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: color),
        ),
      ),
    );
  }
}

/// 命令行风格输入框（用于 Session 页面）
class RpgCommandInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final VoidCallback? onSubmit;

  const RpgCommandInput({
    Key? key,
    required this.controller,
    this.hint,
    this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          ">",
          style: TextStyle(
            color: AppColors.accentSafe,
            fontSize: 18,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapH12,
        Expanded(
          child: TextField(
            controller: controller,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint ?? "Enter command...",
              hintStyle: AppTextStyles.body.copyWith(color: Colors.white24),
            ),
            cursorColor: AppColors.accentSafe,
            onSubmitted: (_) => onSubmit?.call(),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.subdirectory_arrow_left,
            color: AppColors.textDim,
          ),
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
