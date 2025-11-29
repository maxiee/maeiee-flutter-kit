import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/services/time_service.dart';
import '../../../../controllers/matrix_controller.dart';
import 'package:intl/intl.dart';

class TemporalMatrix extends StatelessWidget {
  // 1. 依赖注入：不再使用 GameController
  final QuestService questService = Get.find();
  final TimeService timeService = Get.find();
  final MatrixController c = Get.put(MatrixController());

  TemporalMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515), // 比背景稍亮
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.borderDim),
      ),
      child: Column(
        children: [
          // 1. Header (Date Selector)
          _buildHeader(),

          // 1.5 Day Deadlines Marquee
          Obx(() {
            final selected = timeService.selectedDate.value;

            final dayDeadlines = questService.quests
                .where(
                  (q) =>
                      q.deadline != null &&
                      q.isAllDayDeadline &&
                      q.deadline!.year == selected.year &&
                      q.deadline!.month == selected.month &&
                      q.deadline!.day == selected.day,
                )
                .toList();

            if (dayDeadlines.isEmpty) return const SizedBox.shrink();

            return Container(
              height: AppSpacing.hourRowHeight,
              color: AppColors.accentDanger.withOpacity(0.1),
              padding: AppSpacing.paddingHorizontalMd,
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: AppSpacing.iconSm,
                    color: AppColors.accentDanger,
                  ),
                  AppSpacing.gapH8,
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dayDeadlines.length,
                      separatorBuilder: (_, __) => AppSpacing.gapH12,
                      itemBuilder: (ctx, i) => Center(
                        child: Text(
                          "${dayDeadlines[i].title} [DEADLINE]",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accentDanger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const RpgDivider(),

          // 2. Matrix Body
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              itemCount: 24, // 24小时
              itemBuilder: (ctx, hour) => _buildHourRow(hour),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: AppColors.textSecondary,
              size: AppSpacing.iconLg,
            ),
            onPressed: () => timeService.changeDate(
              timeService.selectedDate.value.subtract(const Duration(days: 1)),
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          Obx(
            () => Text(
              DateFormat('yyyy-MM-dd').format(timeService.selectedDate.value),
              style: AppTextStyles.panelHeader,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: AppSpacing.iconLg,
            ),
            onPressed: () => timeService.changeDate(
              timeService.selectedDate.value.add(const Duration(days: 1)),
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(int hour) {
    return Container(
      height: AppSpacing.hourRowHeight,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          // 标尺
          SizedBox(
            width: 24,
            child: Text(
              hour.toString().padLeft(2, '0'),
              style: AppTextStyles.caption.copyWith(color: AppColors.textDim),
            ),
          ),
          AppSpacing.gapH8,
          // 4个格子
          Expanded(
            child: Row(
              children: [
                _buildRichCapsule(hour, 0),
                const SizedBox(width: 2),
                _buildRichCapsule(hour, 1),
                const SizedBox(width: 2),
                _buildRichCapsule(hour, 2),
                const SizedBox(width: 2),
                _buildRichCapsule(hour, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichCapsule(int hour, int quarter) {
    final index = (hour * 4) + quarter;

    return Expanded(
      child: Obx(() {
        final state = timeService.timeBlocks[index];
        final isSelected = c.isSelected(index);

        // 1. 确定样式
        Color fillColor = Colors.white.withOpacity(0.05); // 默认底色
        Color borderColor = Colors.transparent;
        String? labelText;
        Color textColor = AppColors.textPrimary;

        // 优先级 1: Deadline (最高)
        if (state.deadlineQuestIds.isNotEmpty) {
          final qId = state.deadlineQuestIds.last;
          final quest = questService.quests.firstWhereOrNull(
            (q) => q.id == qId,
          );

          fillColor = AppColors.accentDanger.withOpacity(0.2);
          borderColor = AppColors.accentDanger;
          labelText = quest?.title;
          textColor = AppColors.accentDanger;
        }
        // 优先级 2: Session (占用)
        else if (state.occupiedQuestIds.isNotEmpty) {
          final qId = state.occupiedQuestIds.last;
          final quest = questService.quests.firstWhereOrNull(
            (q) => q.id == qId,
          );
          final colorType = c.getQuestColorType(qId);

          if (colorType == 'orange') {
            fillColor = AppColors.accentMain.withOpacity(0.4);
            borderColor = AppColors.accentMain.withOpacity(0.5);
            textColor = AppColors.accentMain;
          } else {
            fillColor = AppColors.accentSystem.withOpacity(0.4);
            borderColor = AppColors.accentSystem.withOpacity(0.5);
            textColor = AppColors.accentSystem;
          }
          labelText = quest?.title;
        }

        if (isSelected) borderColor = AppColors.textPrimary;

        return GestureDetector(
          onTap: () => c.onBlockTap(index),
          child: Container(
            alignment: Alignment.centerLeft, // 文字左对齐
            padding: const EdgeInsets.symmetric(horizontal: 2), // 极小内边距
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: borderColor),
            ),
            // 文字渲染核心
            child: labelText != null
                ? Text(
                    labelText,
                    style: AppTextStyles.micro.copyWith(color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
