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

  PlayerHud({super.key});

  @override
  Widget build(BuildContext context) {
    return RpgContainer(
      style: RpgContainerStyle.panel,
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
                  child: RpgText.caption(
                    p.playerTitle.value,
                    color: AppColors.accentMain,
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
                    RpgText.micro("LV.${p.playerLevel.value}"),
                    RpgText.micro(
                      "经验: ${p.totalXp.value}",
                      color: AppColors.textDim,
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
        child: RpgText(
          p.playerLevel.value.toString(),
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
              const RpgText.micro("时间分布"),
              // 可以加个小百分比显示
              Obx(
                () => RpgText.micro(
                  "${(t.effectiveRatio.value * 100).toInt()}% 效率",
                  color: AppColors.accentSafe,
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
              _legendDot(AppColors.accentSafe, "有效"),
              _legendDot(const Color(0xFF8B2C2C), "耗散"),
              _legendDot(AppColors.bgCard, "未来"),
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
        RpgText.micro(label, color: Colors.grey),
      ],
    );
  }

  // 右侧：倒计时
  Widget _buildDailyModule() {
    return Row(
      children: [
        Expanded(child: _statColumn(p.dailyXp, "今日产出", AppColors.accentSystem)),
        Container(width: 1, height: 24, color: AppColors.borderDim),
        Expanded(
          child: _statColumn(
            t.timeRemainingStr,
            "距离休眠",
            AppColors.accentDanger,
          ),
        ),
      ],
    );
  }

  Widget _statColumn(Rx<Object> value, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(
          () => Text(
            value.value.toString(),
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        RpgText.micro(label, color: AppColors.textDim),
      ],
    );
  }
}
