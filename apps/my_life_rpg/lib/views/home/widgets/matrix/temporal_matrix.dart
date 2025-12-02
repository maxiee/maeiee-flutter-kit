import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/services/time_service.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/matrix_cell.dart';
import '../../../../controllers/matrix_controller.dart';
import 'package:intl/intl.dart';

class TemporalMatrix extends StatelessWidget {
  // 1. 依赖注入：不再使用 GameController
  final QuestService questService = Get.find();
  final TimeService timeService = Get.find();
  final MatrixController c = Get.find();

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
          _buildDeadlineMarquee(),

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

  Widget _buildDeadlineMarquee() {
    return Obx(() {
      final selected = timeService.selectedDate.value;
      // 这里的逻辑依然比较重，但在 Obx 里也还好
      // 理想情况下应该移到 Controller 的 computed 属性里
      final dayDeadlines = questService.quests.where((q) {
        if (q.deadline == null || !q.isAllDayDeadline) return false;
        return q.deadline!.year == selected.year &&
            q.deadline!.month == selected.month &&
            q.deadline!.day == selected.day;
      }).toList();

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
    });
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
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.textSecondary,
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
            icon: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
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
    final now = DateTime.now();
    final isCurrentHour =
        timeService.selectedDate.value.year == now.year &&
        timeService.selectedDate.value.month == now.month &&
        timeService.selectedDate.value.day == now.day &&
        hour == now.hour;

    return Container(
      height: AppSpacing.hourRowHeight,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Stack(
        children: [
          Row(
            children: [
              // Ruler
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

              // 4个 Smart Cells
              Expanded(
                child: Row(
                  children: [
                    _buildCellWrapper(hour, 0),
                    _buildGap(hour, 0, 1),
                    _buildCellWrapper(hour, 1),
                    _buildGap(hour, 1, 2),
                    _buildCellWrapper(hour, 2),
                    _buildGap(hour, 2, 3),
                    _buildCellWrapper(hour, 3),
                  ],
                ),
              ),
            ],
          ),

          // Now Cursor
          if (isCurrentHour)
            Positioned.fill(
              left: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: now.minute / 60.0,
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 2,
                      height: 16,
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

  // 使用 Expanded 包裹 MatrixCell
  Widget _buildCellWrapper(int hour, int quarter) {
    final index = (hour * 4) + quarter;

    return Expanded(
      child: Obx(() {
        final state = timeService.timeBlocks[index];
        final isSelected = c.isSelected(index);
        final isLeftConnected = c.isConnected(index - 1, index);
        final isRightConnected = c.isConnected(index, index + 1);

        // [修改点]: 调用 MatrixCell 组件
        return MatrixCell(
          state: state,
          isSelected: isSelected,
          isLeftConnected: isLeftConnected,
          isRightConnected: isRightConnected,
          isRowStart: quarter == 0,
          isRowEnd: quarter == 3,
          onTap: () => c.onBlockTap(index),
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
