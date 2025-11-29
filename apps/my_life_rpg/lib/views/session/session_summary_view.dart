// lib/views/session/session_summary_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/logic/rank_logic.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';

class SessionSummaryView extends StatefulWidget {
  final int durationSeconds;
  final int logsCount;
  final int xpEarned;
  final bool isDaemon; // 用于判断显示文案

  const SessionSummaryView({
    Key? key,
    required this.durationSeconds,
    required this.logsCount,
    required this.xpEarned,
    required this.isDaemon,
  }) : super(key: key);

  @override
  State<SessionSummaryView> createState() => _SessionSummaryViewState();
}

class _SessionSummaryViewState extends State<SessionSummaryView>
    with SingleTickerProviderStateMixin {
  late RankResult rankResult;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  bool isMarkedComplete = false; // 用户是否勾选了“完成任务”

  @override
  void initState() {
    super.initState();
    rankResult = RankLogic.calculate(widget.durationSeconds);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                "MISSION DEBRIEF",
                style: AppTextStyles.panelHeader.copyWith(
                  letterSpacing: 4,
                  color: AppColors.textDim,
                ),
              ),
            ),
            AppSpacing.gapV24,

            // 2. Rank (核心视觉)
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rankResult.color.withOpacity(0.5),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rankResult.color.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  rankResult.label,
                  style: AppTextStyles.heroNumber.copyWith(
                    fontSize: 64,
                    color: rankResult.color,
                  ),
                ),
              ),
            ),
            AppSpacing.gapV16,
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                rankResult.comment,
                style: AppTextStyles.body.copyWith(
                  color: rankResult.color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            AppSpacing.gapV32,
            const RpgDivider(indent: 60, endIndent: 60),
            AppSpacing.gapV32,

            // 3. Stats Grid
            FadeTransition(
              opacity: _fadeAnim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(
                    "DURATION",
                    "${widget.durationSeconds ~/ 60}",
                    "m",
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppColors.borderDim,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  _buildStatItem("XP EARNED", "+${widget.xpEarned}", "pts"),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppColors.borderDim,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  _buildStatItem("LOGS", "${widget.logsCount}", "entries"),
                ],
              ),
            ),

            AppSpacing.gapV32,

            // 4. Completion Toggle (完成状态开关)
            FadeTransition(opacity: _fadeAnim, child: _buildCompletionSwitch()),

            AppSpacing.gapV32,

            // 5. Action Buttons (Discard & Confirm)
            FadeTransition(
              opacity: _fadeAnim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 丢弃按钮
                  RpgButton(
                    label: "DISCARD",
                    type: RpgButtonType.ghost,
                    icon: Icons.delete_outline,
                    onTap: () {
                      // 返回 Map: {save: false}
                      Get.back(result: {'save': false});
                    },
                  ),

                  AppSpacing.gapH16,

                  // 确认按钮
                  RpgButton(
                    label: "CONFIRM", // & SAVE 可以省略，简洁点
                    type: RpgButtonType.primary,
                    icon: Icons.save,
                    onTap: () {
                      // 返回 Map: {save: true, complete: bool}
                      Get.back(
                        result: {'save': true, 'complete': isMarkedComplete},
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textDim),
        ),
        AppSpacing.gapV4,
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutExpo,
              builder: (context, val, child) {
                return Text(
                  "$val",
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentMain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionSwitch() {
    final label = widget.isDaemon
        ? "CYCLE COMPLETE (RESET)"
        : "MISSION ACCOMPLISHED";
    final color = widget.isDaemon
        ? AppColors.accentSystem
        : AppColors.accentSafe;

    return GestureDetector(
      onTap: () => setState(() => isMarkedComplete = !isMarkedComplete),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isMarkedComplete
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isMarkedComplete ? color : Colors.white12,
            width: isMarkedComplete ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4), // 方形圆角更符合赛博风格
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMarkedComplete
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isMarkedComplete ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isMarkedComplete ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
