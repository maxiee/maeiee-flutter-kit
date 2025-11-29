import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/app_colors.dart';
import 'package:my_life_rpg/services/time_service.dart';

class PlayerHud extends StatelessWidget {
  final TimeService t = Get.find(); // 直接找 TimeService

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
          // 1. XP Scoreboard (Output)
          _buildScoreBoard(),

          const VerticalDivider(color: Colors.white10, thickness: 1, width: 32),

          // 2. Time Spectrum (Perception)
          Expanded(child: _buildTimeSpectrum()),

          const VerticalDivider(color: Colors.white10, thickness: 1, width: 32),

          // 3. Countdown (Deadline)
          _buildCountdown(),
        ],
      ),
    );
  }

  // 左侧：今日产出
  Widget _buildScoreBoard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "DAILY XP (OUTPUT)",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${t.dailyXp.value}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 24,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "pts",
                style: TextStyle(
                  color: Colors.cyanAccent.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Obx(
          () => Text(
            "DONE: ${t.tasksCompletedToday.value} MISSIONS",
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ],
    );
  }

  // 中部：时间熵光谱
  Widget _buildTimeSpectrum() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "TIME SPECTRUM (DAY CYCLE)",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
            // 可以在这里加个百分比显示
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Obx(
            () => Row(
              children: [
                // 1. 有效时间 (Green)
                Expanded(
                  flex: (t.effectiveRatio.value * 1000).toInt(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                // 2. 熵/耗散 (Red/Dark)
                // 这是最扎心的部分：如果你没记录，这里就是一大片红色
                Expanded(
                  flex: (t.entropyRatio.value * 1000).toInt(),
                  child: Container(color: const Color(0xFF591C1C)), // 暗红色
                ),
                // 3. 未来 (Grey)
                Expanded(
                  flex: (t.futureRatio.value * 1000).toInt(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF333333),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legendDot(Colors.greenAccent, "EFFECTIVE"),
            _legendDot(const Color(0xFF8B2C2C), "ENTROPY (UNKNOWN)"), // 熵
            _legendDot(const Color(0xFF555555), "REMAINING"),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }

  // 右侧：倒计时
  Widget _buildCountdown() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          "T-MINUS (SLEEP)",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Obx(
          () => Text(
            t.timeToSleep.value,
            style: const TextStyle(
              color: AppColors.accentMain,
              fontSize: 20,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "TARGET: 01:00",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}
