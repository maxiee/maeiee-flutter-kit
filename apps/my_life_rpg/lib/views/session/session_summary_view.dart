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
  final VoidCallback onConfirm;

  const SessionSummaryView({
    Key? key,
    required this.durationSeconds,
    required this.logsCount,
    required this.xpEarned,
    required this.onConfirm,
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

    // 启动动画
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
      backgroundColor: Colors.black.withOpacity(0.95), // 几乎全黑，沉浸感
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

            // 3. Stats Grid (带滚动数字动画)
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
            AppSpacing.gapV24,

            // 4. Action
            FadeTransition(
              opacity: _fadeAnim,
              child: RpgButton(
                label: "CONFIRM & SAVE",
                type: RpgButtonType.primary,
                onTap: widget.onConfirm,
                // 加宽按钮
                // padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
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
            // 简单的滚动数字 (TweenAnimationBuilder)
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
}
