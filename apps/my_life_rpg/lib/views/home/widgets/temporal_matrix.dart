import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/game_controller.dart';
import '../../../controllers/matrix_controller.dart';
import 'package:intl/intl.dart';

class TemporalMatrix extends StatelessWidget {
  final GameController game = Get.find();
  final MatrixController c = Get.put(MatrixController());

  TemporalMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515), // 比背景稍亮
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // 1. Header (Date Selector)
          _buildHeader(),

          // 1.5 Day Deadlines Marquee
          Obx(() {
            final dayDeadlines = game.quests
                .where(
                  (q) =>
                      q.deadline != null &&
                      q.isAllDayDeadline &&
                      q.deadline!.year == game.selectedDate.value.year &&
                      q.deadline!.month == game.selectedDate.value.month &&
                      q.deadline!.day == game.selectedDate.value.day,
                )
                .toList();

            if (dayDeadlines.isEmpty) return const SizedBox.shrink();

            return Container(
              height: 24,
              color: Colors.redAccent.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dayDeadlines.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) => Center(
                        child: Text(
                          "${dayDeadlines[i].title} [DEADLINE]",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: 'Courier',
                            fontSize: 10,
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

          const Divider(height: 1, color: Colors.white10),

          // 2. Matrix Body
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
            onPressed: () => game.changeDate(
              game.selectedDate.value.subtract(const Duration(days: 1)),
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          Obx(
            () => Text(
              DateFormat('yyyy-MM-dd').format(game.selectedDate.value),
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onPressed: () => game.changeDate(
              game.selectedDate.value.add(const Duration(days: 1)),
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
      height: 24, // 增加一点高度容纳文字
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // 标尺
          SizedBox(
            width: 24,
            child: Text(
              hour.toString().padLeft(2, '0'),
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
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
        final state = game.timeBlocks[index];
        final isSelected = c.isSelected(index);

        // 1. 确定样式
        Color fillColor = Colors.white.withOpacity(0.05); // 默认底色
        Color borderColor = Colors.transparent;
        String? labelText;
        Color textColor = Colors.white;

        // 优先级 1: Deadline (最高)
        if (state.deadlineQuestIds.isNotEmpty) {
          final qId = state.deadlineQuestIds.last;
          final quest = game.quests.firstWhereOrNull((q) => q.id == qId);

          fillColor = Colors.redAccent.withOpacity(0.2); // 红底
          borderColor = Colors.redAccent;
          labelText = quest?.title; // 标题
          textColor = Colors.redAccent;
        }
        // 优先级 2: Session (占用)
        else if (state.occupiedQuestIds.isNotEmpty) {
          final qId = state.occupiedQuestIds.last;
          final quest = game.quests.firstWhereOrNull((q) => q.id == qId);
          final colorType = c.getQuestColorType(qId);

          if (colorType == 'orange') {
            fillColor = Colors.orangeAccent.withOpacity(0.4);
            borderColor = Colors.orangeAccent.withOpacity(0.5);
            textColor = Colors.orangeAccent;
          } else {
            fillColor = Colors.cyanAccent.withOpacity(0.4);
            borderColor = Colors.cyanAccent.withOpacity(0.5);
            textColor = Colors.cyanAccent;
          }
          labelText = quest?.title;
        }

        if (isSelected) borderColor = Colors.white;

        return GestureDetector(
          onTap: () => c.onBlockTap(index),
          child: Container(
            alignment: Alignment.centerLeft, // 文字左对齐
            padding: const EdgeInsets.symmetric(horizontal: 2), // 极小内边距
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: borderColor),
            ),
            // 文字渲染核心
            child: labelText != null
                ? Text(
                    labelText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 7, // 7px 像素字体感
                      fontFamily: 'Courier', // 等宽字体在小尺寸下更易读
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // 允许两行
                    overflow: TextOverflow.clip, // 直接截断，不显示省略号省空间
                  )
                : null,
          ),
        );
      }),
    );
  }
}
