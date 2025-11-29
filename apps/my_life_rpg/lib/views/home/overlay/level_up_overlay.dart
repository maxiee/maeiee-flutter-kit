import 'package:flutter/material.dart';
// 获取头衔逻辑
import 'package:my_life_rpg/core/theme/theme.dart';

class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    Key? key,
    required this.newLevel,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _opacityAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 计算头衔 (为了获取最新头衔，这里暂时临时计算一下，或者传进来)
  String get title => _getTitle(widget.newLevel);

  String _getTitle(int level) {
    if (level >= 60) return "CYBER DEITY";
    if (level >= 50) return "SYSTEM ARCHITECT";
    if (level >= 40) return "NETRUNNER LEGEND";
    if (level >= 30) return "SENIOR OPERATOR";
    if (level >= 20) return "CONSOLE COWBOY";
    if (level >= 10) return "SCRIPT KIDDIE";
    return "NOVICE";
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: InkWell(
        onTap: widget.onDismiss, // 点击任意处关闭
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. LEVEL UP TEXT
              FadeTransition(
                opacity: _opacityAnim,
                child: Text(
                  "SYSTEM UPGRADE",
                  style: AppTextStyles.panelHeader.copyWith(
                    color: AppColors.accentMain,
                    letterSpacing: 4.0,
                    fontSize: 16,
                  ),
                ),
              ),
              AppSpacing.gapV32,

              // 2. BIG NUMBER
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 160,
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentMain, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentMain.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                    color: Colors.black,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "LV.",
                        style: AppTextStyles.micro.copyWith(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${widget.newLevel}",
                        style: AppTextStyles.heroNumber.copyWith(
                          fontSize: 64,
                          color: AppColors.accentMain,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapV32,

              // 3. NEW TITLE
              FadeTransition(
                opacity: _opacityAnim,
                child: Column(
                  children: [
                    Text(
                      "ACCESS GRANTED:",
                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                    ),
                    AppSpacing.gapV8,
                    Text(
                      title,
                      style: AppTextStyles.panelHeader.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapV32,
              AppSpacing.gapV32,

              // 4. Prompt
              FadeTransition(
                opacity: _opacityAnim,
                child: Text(
                  "[ TAP TO ACKNOWLEDGE ]",
                  style: AppTextStyles.micro.copyWith(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
