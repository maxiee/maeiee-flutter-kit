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

      return RpgContainer(
        style: RpgContainerStyle.card,
        overrideColor: AppColors.accentDanger,
        height: AppSpacing.hourRowHeight + 8, // 稍微高一点
        padding: AppSpacing.paddingHorizontalMd,
        // 这里不需要圆角背景，因为通常 Marquee 是长条形的。
        // 但为了保持一致性，我们可以让它看起来像个 Alert 条
        margin: const EdgeInsets.only(bottom: 1), // 分隔线
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
          // Layer 1: 背景网格 (Cells)
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

          // Layer 2: 智能文字层 (Labels) - [新增]
          // 这里的 padding left = 24 (Ruler) + 8 (Gap) = 32
          Positioned.fill(
            left: 32,
            child: IgnorePointer(
              // 文字层不拦截点击
              child: _buildLabelLayer(hour),
            ),
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

  Widget _buildLabelLayer(int hour) {
    return Obx(() {
      return Row(
        children: List.generate(7, (k) {
          // 偶数是格子，奇数是 Gap
          if (k % 2 != 0) return const SizedBox(width: 2); // Gap

          final quarter = k ~/ 2;
          final index = (hour * 4) + quarter;
          final state = timeService.timeBlocks[index];

          // 空格子 -> 占位
          if (state.occupiedSessionIds.isEmpty) {
            return const Expanded(child: SizedBox());
          }

          // 占用格子
          // 核心逻辑：只有当它是 "本行内该 Session 的第一块" 时，才渲染文字
          // 并且计算它在本行剩余的长度，作为 Overflow 的约束

          final String currentSessionId = state.occupiedSessionIds.last;

          // 检查前一个格子是否是同一个 Session (在本行内)
          bool isContinuation = false;
          if (quarter > 0) {
            final prevIndex = index - 1;
            final prevState = timeService.timeBlocks[prevIndex];
            if (prevState.occupiedSessionIds.isNotEmpty &&
                prevState.occupiedSessionIds.last == currentSessionId) {
              isContinuation = true;
            }
          }

          if (isContinuation) {
            // 如果是延续，只占位，不渲染文字
            return const Expanded(child: SizedBox());
          }

          // 如果是新的片段 (Start of segment in this row)
          // 计算剩余长度，以便显示更长的文字
          int span = 1;
          for (int j = quarter + 1; j < 4; j++) {
            final nextIdx = (hour * 4) + j;
            final nextSt = timeService.timeBlocks[nextIdx];
            if (nextSt.occupiedSessionIds.isNotEmpty &&
                nextSt.occupiedSessionIds.last == currentSessionId) {
              span++;
            } else {
              break;
            }
          }

          // 获取文字
          String label = "";
          final quest = questService.quests.firstWhereOrNull(
            (q) => q.id == state.occupiedQuestIds.last,
          );
          if (quest != null) label = quest.title;

          return Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                // 计算允许的总宽度: (单格宽度 * span) + (间隙宽度 * (span-1))
                // constraints.maxWidth 是单格宽度
                final totalWidth =
                    (constraints.maxWidth * span) + ((span - 1) * 2.0);

                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: totalWidth, // 允许文字跨越 span 个格子
                  child: Container(
                    width: totalWidth, // 强制占满计算出的宽度
                    padding: const EdgeInsets.only(left: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: AppTextStyles.micro.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 2),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // 超出 span 长度后省略
                    ),
                  ),
                );
              },
            ),
          );
        }),
      );
    });
  }
}
