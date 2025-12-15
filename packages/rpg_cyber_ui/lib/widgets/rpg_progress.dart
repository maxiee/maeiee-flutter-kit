// lib/core/widgets/rpg_progress.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// RPG 风格进度条
class RpgProgress extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final bool showGlow;

  const RpgProgress({
    Key? key,
    required this.value,
    this.height = 2.0,
    this.color,
    this.backgroundColor,
    this.showGlow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppColors.accentMain;

    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusSm,
      child: Container(
        height: height,
        width: double.infinity, // [关键修改]：强制占满父容器宽度
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black,
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: progressColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(color: progressColor),
        ),
      ),
    );
  }
}

/// 时间频谱条（用于 HUD 的时间分布可视化）
class RpgTimeSpectrum extends StatelessWidget {
  final double effectiveRatio;
  final double entropyRatio;
  final double futureRatio;
  final double height;

  const RpgTimeSpectrum({
    Key? key,
    required this.effectiveRatio,
    required this.entropyRatio,
    required this.futureRatio,
    this.height = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF8B2C2C),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          // 有效时间 (Green)
          Expanded(
            flex: (effectiveRatio * 1000).toInt().clamp(0, 1000),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.accentSafe,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          // 熵/耗散 (Dark Red)
          Expanded(
            flex: (entropyRatio * 1000).toInt().clamp(0, 1000),
            child: const ColoredBox(color: Color(0xFF591C1C)),
          ),
          // 未来 (Grey)
          Expanded(
            flex: (futureRatio * 1000).toInt().clamp(0, 1000),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
