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
    Key? key,
    required this.state,
    required this.isSelected,
    required this.isLeftConnected,
    required this.isRightConnected,
    required this.isRowStart,
    required this.isRowEnd,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. 样式计算 (只计算背景和边框)
    Color fillColor = Colors.white.withOpacity(0.05);
    Color borderColor = Colors.transparent;
    String? tooltipMessage; // [新增]

    final QuestService qs = Get.find();

    if (state.deadlineQuestIds.isNotEmpty) {
      fillColor = AppColors.accentDanger.withOpacity(0.2);
      borderColor = AppColors.accentDanger;
      // 查找 deadline 标题
      final qId = state.deadlineQuestIds.first;
      final quest = qs.quests.firstWhereOrNull((q) => q.id == qId);
      tooltipMessage = "${quest?.title ?? 'Unknown'} [DEADLINE]";
    } else if (state.occupiedSessionIds.isNotEmpty) {
      final qId = state.occupiedQuestIds.last;
      final quest = qs.quests.firstWhereOrNull((q) => q.id == qId);

      if (quest != null) {
        final baseColor = AppColors.getQuestColor(quest.type);
        fillColor = baseColor.withOpacity(0.4);
        borderColor = baseColor.withOpacity(0.5);
        tooltipMessage = quest.title; // [新增]
      }
    }

    if (isSelected) borderColor = Colors.white;

    // 2. 形状计算
    BorderRadius radius;
    if (state.occupiedSessionIds.isEmpty) {
      radius = BorderRadius.circular(2);
    } else {
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
    // [修改]: 移除内部 Text，包裹 Tooltip
    return Tooltip(
      message: tooltipMessage ?? "",
      // 只有有内容时才显示 Tooltip
      triggerMode: tooltipMessage != null ? TooltipTriggerMode.longPress : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
        ),
      ),
    );
  }
}
