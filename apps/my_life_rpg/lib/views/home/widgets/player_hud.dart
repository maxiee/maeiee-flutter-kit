import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/game_controller.dart';

/// 赛博朋克风格的仪表盘。
class PlayerHud extends StatelessWidget {
  final GameController c = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // HP 模块 (左侧)
          _buildHpSelector(),

          const SizedBox(width: 24),

          // MP 模块 (右侧，进度条)
          Expanded(child: _buildMpBar()),
        ],
      ),
    );
  }

  Widget _buildHpSelector() {
    return Obx(
      () => Row(
        children: [
          const Text(
            "STATUS: ",
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          _hpButton("HIGH", Colors.green, c.hp.value == "HIGH"),
          const SizedBox(width: 8),
          _hpButton("NORMAL", Colors.blue, c.hp.value == "NORMAL"),
          const SizedBox(width: 8),
          _hpButton("LOW", Colors.red, c.hp.value == "LOW"),
        ],
      ),
    );
  }

  Widget _hpButton(String label, Color color, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        border: Border.all(
          color: isActive ? color : Colors.grey.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? color : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMpBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "MP (TIME ENERGY)",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
            Obx(
              () => Text(
                "${c.mpCurrent.value}h / ${c.mpTotal}h",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Obx(
          () => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.mpCurrent.value / c.mpTotal,
              backgroundColor: Colors.black,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.cyanAccent,
              ),
              minHeight: 12,
            ),
          ),
        ),
      ],
    );
  }
}
