import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// 统一风格的下拉选择器
class RpgSelect<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;

  const RpgSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
          AppSpacing.gapV8,
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.borderDim),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppColors.bgCard,
              style: AppTextStyles.body,
              isExpanded: true,
              hint: hint != null
                  ? Text(
                      hint!,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                      ),
                    )
                  : null,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
