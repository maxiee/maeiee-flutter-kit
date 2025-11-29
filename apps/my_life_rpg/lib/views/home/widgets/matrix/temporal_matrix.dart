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
    // 检查是否是当前小时 (用于画 Now Line)
    final now = DateTime.now();
    final isCurrentHour =
        timeService.selectedDate.value.year == now.year &&
        timeService.selectedDate.value.month == now.month &&
        timeService.selectedDate.value.day == now.day &&
        hour == now.hour;

    return Container(
      height: AppSpacing.hourRowHeight,
      margin: const EdgeInsets.only(
        bottom: AppSpacing.xs,
      ), // 行间距保持不变，行与行之间还是断开的
      child: Stack(
        //以此支持 Now Line 叠加
        children: [
          Row(
            children: [
              // 标尺
              SizedBox(
                width: 24,
                child: Text(
                  hour.toString().padLeft(2, '0'),
                  style: AppTextStyles.caption.copyWith(
                    color: isCurrentHour
                        ? AppColors.accentDanger
                        : AppColors.textDim,
                    fontWeight: isCurrentHour
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              AppSpacing.gapH8,

              // 4个格子 (使用自定义构建逻辑)
              Expanded(
                child: Row(
                  children: [
                    _buildSmartCapsule(hour, 0),
                    _buildGap(hour, 0, 1),
                    _buildSmartCapsule(hour, 1),
                    _buildGap(hour, 1, 2),
                    _buildSmartCapsule(hour, 2),
                    _buildGap(hour, 2, 3),
                    _buildSmartCapsule(hour, 3),
                  ],
                ),
              ),
            ],
          ),

          // Now Line 指针
          // Now Cursor (Vertical Line)
          if (isCurrentHour)
            Positioned.fill(
              left: 32, // 跳过标尺
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: now.minute / 60.0,
                  child: Container(
                    alignment: Alignment.centerRight, // 靠右边
                    child: Container(
                      width: 2,
                      height: 16, // 比行高略矮
                      decoration: BoxDecoration(
                        color: AppColors.accentDanger,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentDanger.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmartCapsule(int hour, int quarter) {
    final index = (hour * 4) + quarter;

    return Expanded(
      child: Obx(() {
        final state = timeService.timeBlocks[index];
        final isSelected = c.isSelected(index);

        // --- 样式计算逻辑 (复用之前的，稍作简化) ---
        Color fillColor = Colors.white.withOpacity(0.05);
        Color borderColor = Colors.transparent;
        String? labelText;
        Color textColor = AppColors.textPrimary;

        if (state.deadlineQuestIds.isNotEmpty) {
          // ... deadline 逻辑 ...
          fillColor = AppColors.accentDanger.withOpacity(0.2);
          borderColor = AppColors.accentDanger;
          // deadline 一般不连
        } else if (state.occupiedSessionIds.isNotEmpty) {
          final qId = state.occupiedQuestIds.last; // 这里为了取颜色还是得用 QuestId
          // [重构点]：直接通过 QuestService 获取 Quest 对象，然后问 AppColors 要颜色
          // 这里稍微有点性能损耗（在 build 里遍历查找），但对于 96 个格子来说微不足道
          // 优化方案：BlockState 里直接存 type 或 color，但那是下一步的事
          final quest = questService.quests.firstWhereOrNull(
            (q) => q.id == qId,
          );
          if (quest != null) {
            // 使用统一的颜色获取方法
            final baseColor = AppColors.getQuestColor(quest.type);

            fillColor = baseColor.withOpacity(0.4);
            borderColor = baseColor.withOpacity(0.5);

            // 标签逻辑
            final isLeftConnected = c.isConnected(index - 1, index);
            if (!isLeftConnected) {
              labelText = quest.title;
            }
          }
        }

        if (isSelected) borderColor = Colors.white;

        // --- 连贯性形状计算 ---
        final isLeftConnected = c.isConnected(index - 1, index);
        final isRightConnected = c.isConnected(index, index + 1);

        // 只有同一行才连 (跨行很难看)
        final isRowStart = quarter == 0;
        final isRowEnd = quarter == 3;

        BorderRadius radius = BorderRadius.zero;

        if (state.occupiedSessionIds.isEmpty) {
          // 空白格：保持默认圆角
          radius = BorderRadius.circular(2);
        } else {
          // 占用格：根据连接情况
          radius = BorderRadius.horizontal(
            left: (isLeftConnected && !isRowStart)
                ? Radius.zero
                : const Radius.circular(2),
            right: (isRightConnected && !isRowEnd)
                ? Radius.zero
                : const Radius.circular(2),
          );
        }

        return GestureDetector(
          onTap: () => c.onBlockTap(index),
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
      }),
    );
  }

  // 动态间距
  Widget _buildGap(int hour, int leftQ, int rightQ) {
    final leftIndex = (hour * 4) + leftQ;
    final rightIndex = (hour * 4) + rightQ;

    return Obx(() {
      // 如果左右相连，且属于同一 Session，则间距为 0
      if (c.isConnected(leftIndex, rightIndex)) {
        return const SizedBox(width: 0);
      }
      return const SizedBox(width: 2);
    });
  }
}
