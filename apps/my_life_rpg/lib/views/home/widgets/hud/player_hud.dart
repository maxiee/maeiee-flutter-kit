import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/time_service.dart';

class PlayerHud extends StatelessWidget {
  final TimeService t = Get.find(); // 直接找 TimeService

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.borderDim),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // 1. XP Scoreboard (Output)
          _buildScoreBoard(),

          const RpgVerticalDivider(),

          // 2. Time Spectrum (Perception)
          Expanded(child: _buildTimeSpectrum()),

          const RpgVerticalDivider(),

          // 3. Countdown (Deadline)
          _buildCountdown(),
        ],
      ),
    );
  }

  // 左侧：今日产出
  Widget _buildScoreBoard() {
    return Obx(
      () => RpgStatBlock(
        label: "DAILY XP (OUTPUT)",
        value: "${t.dailyXp.value}",
        suffix: "pts",
        valueColor: AppColors.accentSystem,
        subtitle: "DONE: ${t.tasksCompletedToday.value} MISSIONS",
      ),
    );
  }

  // 中部：时间熵光谱
  Widget _buildTimeSpectrum() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TIME SPECTRUM (DAY CYCLE)",
          style: AppTextStyles.caption.copyWith(color: Colors.grey),
        ),
        AppSpacing.gapV8,
        Obx(
          () => RpgTimeSpectrum(
            effectiveRatio: t.effectiveRatio.value,
            entropyRatio: t.entropyRatio.value,
            futureRatio: t.futureRatio.value,
          ),
        ),
        AppSpacing.gapV4,
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legendDot(AppColors.accentSafe, "EFFECTIVE"),
            _legendDot(const Color(0xFF8B2C2C), "ENTROPY (UNKNOWN)"),
            _legendDot(AppColors.bgCard, "REMAINING"),
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
        AppSpacing.gapH4,
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.grey)),
      ],
    );
  }

  // 右侧：倒计时
  Widget _buildCountdown() {
    return Obx(
      () => RpgCountdown(
        label: "T-MINUS (SLEEP)",
        time: t.timeRemainingStr.value,
        target: "TARGET: 01:00",
        color: AppColors.accentMain,
      ),
    );
  }
}
