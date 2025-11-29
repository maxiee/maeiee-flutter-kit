import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/game_controller.dart';
import '../../../controllers/matrix_controller.dart';
import 'package:intl/intl.dart';

class TemporalMatrix extends StatelessWidget {
  final GameController game = Get.find();
  final MatrixController c = Get.put(MatrixController());

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Left: Hour Label (08, 09...)
          SizedBox(
            width: 24,
            child: Text(
              hour.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white30,
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right: 4 Capsules
          Expanded(
            child: Row(
              children: [
                _buildCapsule(hour, 0),
                const SizedBox(width: 4),
                _buildCapsule(hour, 1),
                const SizedBox(width: 4),
                _buildCapsule(hour, 2),
                const SizedBox(width: 4),
                _buildCapsule(hour, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsule(int hour, int quarter) {
    final index = (hour * 4) + quarter;

    return Expanded(
      child: Obx(() {
        final state = game.timeBlocks[index];
        final isSelected = c.isSelected(index);

        // --- 1. 计算填充色 (Session) ---
        Color fillColor = Colors.transparent;
        if (state.occupiedQuestIds.isNotEmpty) {
          // 获取第一个任务的颜色 (简化处理，不做多色混合)
          final qId = state.occupiedQuestIds.last; // 显示最新的
          final colorType = c.getQuestColorType(qId);

          if (colorType == 'orange')
            fillColor = Colors.orangeAccent.withOpacity(0.6);
          else if (colorType == 'cyan')
            fillColor = Colors.cyanAccent.withOpacity(0.6);
        }

        // --- 2. 计算 Deadline 视觉 ---
        bool hasDeadline = state.deadlineQuestIds.isNotEmpty;
        Color borderColor = Colors.white12;
        if (hasDeadline) {
          borderColor = Colors.redAccent; // 红色警戒
        } else if (isSelected) {
          borderColor = Colors.white;
        }

        // --- 3. 构造组件 ---
        return GestureDetector(
          onTap: () => c.onBlockTap(index),
          // Tooltip 用于展示多任务交错的详情
          onLongPress: () {
            if (!state.isEmpty) {
              // Show snackbar or dialog with list of tasks in this block
              Get.snackbar(
                "Block Details",
                "Occupied: ${state.occupiedQuestIds.length}\nDeadlines: ${state.deadlineQuestIds.length}",
                snackPosition: SnackPosition.TOP,
              );
            }
          },
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(2), // 方一点
              border: Border.all(
                color: borderColor,
                width: hasDeadline
                    ? 2
                    : (isSelected ? 1.5 : 1), // Deadline 边框加粗
              ),
              boxShadow: hasDeadline
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ]
                  : [],
            ),
            // 如果既有任务又有 Deadline，或者有多个任务，加个小点提示
            child: (state.occupiedQuestIds.length > 1)
                ? Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}
