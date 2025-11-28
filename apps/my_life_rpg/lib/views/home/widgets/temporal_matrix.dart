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
        final colorType = c.getBlockColor(index);
        final isSelected = c.isSelected(index);

        Color fillColor = Colors.transparent;
        Color borderColor = Colors.white12;

        // 状态映射颜色
        if (colorType == 'orange') {
          fillColor = Colors.orangeAccent.withOpacity(0.6);
          borderColor = Colors.orangeAccent;
        } else if (colorType == 'cyan') {
          fillColor = Colors.cyanAccent.withOpacity(0.6);
          borderColor = Colors.cyanAccent;
        }

        // 选中状态覆盖
        if (isSelected) {
          borderColor = Colors.white;
          fillColor = fillColor == Colors.transparent
              ? Colors.white.withOpacity(0.2)
              : fillColor.withOpacity(0.9);
        }

        return GestureDetector(
          onTap: () => c.onBlockTap(index),
          child: Container(
            height: 14, // 胶囊高度
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(4), // 胶囊圆角
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1, // 选中加粗
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }
}
