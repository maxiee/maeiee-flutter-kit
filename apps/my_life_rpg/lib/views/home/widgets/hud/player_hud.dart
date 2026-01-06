import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/views/home/widgets/data_backup_dialog.dart';
import 'package:my_life_rpg/views/home/widgets/tactical_analysis_dialog.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/services/performance_service.dart';
import 'package:my_life_rpg/services/time_service.dart';

class PlayerHud extends StatelessWidget {
  final TimeService t = Get.find(); // 直接找 TimeService
  final PerformanceService p = Get.find();

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
            // 1. Output Metrics (30%) - 产出指标
            Expanded(flex: 30, child: _buildOutputModule()),

            const RpgVerticalDivider(indent: 8, endIndent: 8),

            // 2. Time Spectrum (40%) - 时间光谱
            Expanded(flex: 40, child: _buildTimeSpectrum()),

            const RpgVerticalDivider(indent: 8, endIndent: 8),

            // 3. System Status (30%) - 系统状态
            Expanded(flex: 30, child: _buildSystemModule()),
          ],
        ),
      ),
    );
  }

  // 左侧：累计产出
  Widget _buildOutputModule() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RpgText.caption("累计产出", color: Colors.grey),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            InkWell(
              onLongPress: () => Get.dialog(const DataBackupDialog()),
              child: Obx(
                () => Text(
                  p.totalHoursStr,
                  style: AppTextStyles.heroNumber.copyWith(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 4),
            RpgText.caption("HOURS", color: AppColors.accentMain),
          ],
        ),
        Obx(
          () => RpgText.micro(
            "COMPLETION RATE: ${p.completionRateStr}",
            color: AppColors.textDim,
          ),
        ),
      ],
    );
  }

  // 中部：时间熵光谱
  Widget _buildTimeSpectrum() {
    // 移除这里的 Expanded，由父级控制
    return InkWell(
      onTap: () => Get.dialog(TacticalAnalysisDialog()), // 弹出分析
      child: Padding(
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

  // 右侧：今日 & 倒计时
  Widget _buildSystemModule() {
    return Row(
      children: [
        Expanded(
          child: _statColumn(
            obsValue: p.dailyHoursStr.obs, // 需要转一下类型或者直接改 _statColumn 签名
            label: "TODAY (H)",
            color: AppColors.accentSystem,
          ),
        ),
        Container(width: 1, height: 24, color: AppColors.borderDim),
        Expanded(
          child: _statColumn(
            obsValue: t.timeRemainingStr,
            label: "T-MINUS",
            color: AppColors.accentDanger,
          ),
        ),
      ],
    );
  }

  Widget _statColumn({
    required RxString obsValue,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(
          () => Text(
            obsValue.value,
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
