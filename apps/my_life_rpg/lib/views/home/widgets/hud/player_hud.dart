import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/utils/logger.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/player_service.dart';
import 'package:my_life_rpg/services/time_service.dart';
import 'package:my_life_rpg/views/debug/debug_console.dart';

class PlayerHud extends StatelessWidget {
  final TimeService t = Get.find(); // 直接找 TimeService
  final PlayerService p = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // 使用 IntrinsicHeight 确保分割线高度一致
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 1. Identity (30%) - 身份卡
            Expanded(flex: 30, child: _buildIdentityModule()),

            const RpgVerticalDivider(indent: 8, endIndent: 8),

            // 2. Time Spectrum (40%) - 时间光谱
            Expanded(flex: 40, child: _buildTimeSpectrum()),

            const RpgVerticalDivider(indent: 8, endIndent: 8),

            // 3. Daily Stats (30%) - 仪表盘
            // 改为 Flex 30，给它更多呼吸空间
            Expanded(flex: 30, child: _buildDailyModule()),
          ],
        ),
      ),
    );
  }

  // 左侧：今日产出
  Widget _buildIdentityModule() {
    return Row(
      children: [
        _buildLevelBadge(),
        AppSpacing.gapH12,
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Obx(
                () => InkWell(
                  // [修改] 包裹 InkWell
                  onDoubleTap: () {
                    // 触发控制台
                    LogService.d("Console requested by user", tag: "HUD");
                    Get.dialog(
                      DebugConsole(),
                      barrierColor: Colors.transparent,
                    );
                  },
                  child: Text(
                    p.playerTitle.value,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentMain,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              AppSpacing.gapV4,

              // Progress Bar
              Obx(
                () => RpgProgress(
                  value: p.levelProgress.value,
                  height: 6,
                  color: AppColors.accentMain,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  showGlow: true,
                ),
              ),

              AppSpacing.gapV4,

              // LV & Total XP
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "LV.${p.playerLevel.value}",
                      style: AppTextStyles.micro.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "TOT: ${p.totalXp.value}",
                      style: AppTextStyles.micro.copyWith(
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 右侧留一点空隙给分割线
        AppSpacing.gapH8,
      ],
    );
  }

  Widget _buildLevelBadge() {
    return Obx(
      () => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentMain.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentMain.withOpacity(0.2),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          "${p.playerLevel.value}",
          style: AppTextStyles.heroNumber.copyWith(fontSize: 18),
        ),
      ),
    );
  }

  // 中部：时间熵光谱
  Widget _buildTimeSpectrum() {
    // 移除这里的 Expanded，由父级控制
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TEMPORAL SPECTRUM",
                style: AppTextStyles.micro.copyWith(letterSpacing: 1.5),
              ),
              // 可以加个小百分比显示
              Obx(
                () => Text(
                  "${(t.effectiveRatio.value * 100).toInt()}% EFFICIENCY",
                  style: AppTextStyles.micro.copyWith(
                    color: AppColors.accentSafe,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV8,
          Obx(
            () => RpgTimeSpectrum(
              effectiveRatio: t.effectiveRatio.value,
              entropyRatio: t.entropyRatio.value,
              futureRatio: t.futureRatio.value,
              height: 12, // 稍微调细一点，更精致
            ),
          ),
          AppSpacing.gapV4,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendDot(AppColors.accentSafe, "ACTIVE"),
              _legendDot(const Color(0xFF8B2C2C), "ENTROPY"),
              _legendDot(AppColors.bgCard, "FUTURE"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.micro.copyWith(color: Colors.grey, fontSize: 8),
        ),
      ],
    );
  }

  // 右侧：倒计时
  Widget _buildDailyModule() {
    // 使用 Row 将两个数据并排，填满空间
    return Row(
      children: [
        // 1. Daily XP (Output)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
            children: [
              Obx(
                () => Text(
                  "+${p.dailyXp.value}",
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 22, // 字体加大
                    color: AppColors.accentSystem,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "DAILY XP",
                style: AppTextStyles.micro.copyWith(color: AppColors.textDim),
              ),
            ],
          ),
        ),

        // 微型分割线
        Container(width: 1, height: 24, color: AppColors.borderDim),

        // 2. Sleep Timer (Deadline)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
            children: [
              Obx(
                () => Text(
                  t.timeRemainingStr.value,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 22, // 字体加大
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "T-MINUS",
                style: AppTextStyles.micro.copyWith(color: AppColors.textDim),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
