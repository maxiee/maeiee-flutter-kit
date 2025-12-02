import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/models/block_state.dart';
import 'package:my_life_rpg/services/quest_service.dart';

class MatrixCell extends StatelessWidget {
  final BlockState state;
  final bool isSelected;
  final bool isLeftConnected;
  final bool isRightConnected;
  final bool isRowStart;
  final bool isRowEnd;
  final VoidCallback onTap;

  const MatrixCell({
    super.key,
    required this.state,
    required this.isSelected,
    required this.isLeftConnected,
    required this.isRightConnected,
    required this.isRowStart,
    required this.isRowEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 样式计算
    Color fillColor = Colors.white.withOpacity(0.05);
    Color borderColor = Colors.transparent;
    String? labelText;
    Color textColor = AppColors.textPrimary;

    // 获取 Service 用于查找 Quest 信息
    // (性能优化注：虽然在 build 里 find 不是很完美，但对于 96 个格子来说损耗可忽略。
    // 极致优化是由父组件传入 Quest 对象，但那样父组件逻辑会变重，此处取折中)
    final QuestService qs = Get.find();

    if (state.deadlineQuestIds.isNotEmpty) {
      fillColor = AppColors.accentDanger.withOpacity(0.2);
      borderColor = AppColors.accentDanger;
    } else if (state.occupiedSessionIds.isNotEmpty) {
      final qId = state.occupiedQuestIds.last;
      final quest = qs.quests.firstWhereOrNull((q) => q.id == qId);

      if (quest != null) {
        final baseColor = AppColors.getQuestColor(quest.type);
        fillColor = baseColor.withOpacity(0.4);
        borderColor = baseColor.withOpacity(0.5);

        // 只有当左侧没有连接时，才显示标题（避免长条 Session 重复显示）
        if (!isLeftConnected) {
          labelText = quest.title;
        }
      }
    }

    // 选中覆盖色
    if (isSelected) borderColor = Colors.white;

    // 2. 形状计算 (连接逻辑)
    BorderRadius radius;
    if (state.occupiedSessionIds.isEmpty) {
      // 空白格：独立圆角
      radius = BorderRadius.circular(2);
    } else {
      // 占用格：处理连接
      radius = BorderRadius.horizontal(
        left: (isLeftConnected && !isRowStart)
            ? Radius.zero
            : const Radius.circular(2),
        right: (isRightConnected && !isRowEnd)
            ? Radius.zero
            : const Radius.circular(2),
      );
    }

    // 3. 渲染
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: radius,
          border: Border.all(color: borderColor),
        ),
        child: labelText != null
            ? Text(
                labelText,
                style: AppTextStyles.micro.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.clip,
              )
            : null,
      ),
    );
  }
}
