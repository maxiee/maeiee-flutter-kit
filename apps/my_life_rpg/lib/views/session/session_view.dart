import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import '../../controllers/session_controller.dart';
import '../../models/quest.dart';

class SessionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.put(SessionController());

    return Scaffold(
      backgroundColor: AppColors.bgDarkest, // 比首页更深一点，更沉浸
      body: SafeArea(
        child: Column(
          children: [
            // 1. 顶部状态栏 (Header)
            _buildHeader(c),

            // 2. 呼吸计时器 (Pulse Timer)
            _buildPulseTimer(c),

            const RpgDivider(),

            // 3. 战术日志流 (The Stream)
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: c.scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: c.displayLogs.length,
                  itemBuilder: (ctx, i) => _buildLogRow(c, c.displayLogs[i]),
                ),
              ),
            ),

            // 4. 控制台 (Command Deck)
            _buildCommandDeck(c),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SessionController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal,
                color: AppColors.textDim,
                size: AppSpacing.iconMd,
              ),
              AppSpacing.gapH8,
              Text(c.quest.title, style: AppTextStyles.panelHeader),
            ],
          ),
          // 退出按钮
          RpgButton(
            label: "TERMINATE",
            type: RpgButtonType.danger,
            compact: true,
            onTap: c.endSession,
          ),
        ],
      ),
    );
  }

  Widget _buildPulseTimer(SessionController c) {
    return AnimatedBuilder(
      animation: c.pulseAnimation,
      builder: (ctx, child) {
        return Container(
          width: double.infinity,
          padding: AppSpacing.paddingVerticalLg + AppSpacing.paddingVerticalMd,
          color: const Color(0xFF151515),
          child: Column(
            children: [
              Obx(
                () => Text(
                  c.formatDuration(c.durationSeconds.value),
                  style: AppTextStyles.heroNumber.copyWith(
                    color: AppColors.accentMain.withOpacity(
                      c.pulseAnimation.value,
                    ),
                    shadows: [
                      BoxShadow(
                        color: AppColors.accentMain.withOpacity(
                          0.3 * c.pulseAnimation.value,
                        ),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapV4,
              Text(
                "SESSION IN PROGRESS",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textDim,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogRow(SessionController c, QuestLog log) {
    Color typeColor;
    IconData typeIcon;

    switch (log.type) {
      case LogType.milestone:
        typeColor = Colors.amberAccent;
        typeIcon = Icons.flag;
        break;
      case LogType.bug:
        typeColor = AppColors.accentDanger;
        typeIcon = Icons.bug_report;
        break;
      case LogType.idea:
        typeColor = AppColors.accentSystem;
        typeIcon = Icons.lightbulb;
        break;
      case LogType.rest:
        typeColor = AppColors.accentSafe;
        typeIcon = Icons.coffee;
        break;
      default:
        typeColor = AppColors.textSecondary;
        typeIcon = Icons.arrow_right;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Text(
            c.formatTime(log.createdAt).split(' ')[1], // 只显示时间
            style: AppTextStyles.body.copyWith(
              color: AppColors.textDim,
              fontSize: 12,
            ),
          ),
          AppSpacing.gapH12,
          // Icon
          Icon(typeIcon, color: typeColor, size: AppSpacing.iconSm),
          AppSpacing.gapH8,
          // Content
          Expanded(
            child: Text(
              log.content,
              style: AppTextStyles.body.copyWith(
                color: typeColor == AppColors.textSecondary
                    ? AppColors.textSecondary
                    : typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandDeck(SessionController c) {
    return RpgContainer(
      child: Column(
        children: [
          // 1. Macros Bar (宏指令栏)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.paddingSm,
            child: Row(
              children: [
                RpgMacroChip(
                  label: "🐛 BUG",
                  color: AppColors.accentDanger,
                  onTap: () => c.triggerMacro("🐛 BUG", LogType.bug, "[BUG]"),
                ),
                AppSpacing.gapH8,
                RpgMacroChip(
                  label: "🚩 节点",
                  color: Colors.amber,
                  onTap: () =>
                      c.triggerMacro("🚩 节点", LogType.milestone, "[节点]"),
                ),
                AppSpacing.gapH8,
                RpgMacroChip(
                  label: "💡 灵感",
                  color: AppColors.accentSystem,
                  onTap: () => c.triggerMacro("💡 灵感", LogType.idea, "[灵感]"),
                ),
                AppSpacing.gapH8,
                RpgMacroChip(
                  label: "☕ 休息",
                  color: AppColors.accentSafe,
                  onTap: () => c.triggerMacro("☕ 休息", LogType.rest, ""),
                ),
                AppSpacing.gapH8,
                RpgMacroChip(
                  label: "📝 笔记",
                  color: Colors.grey,
                  onTap: () => c.triggerMacro("📝 笔记", LogType.normal, ""),
                ),
              ],
            ),
          ),

          // 2. Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: RpgCommandInput(
              controller: c.textController,
              hint: "Enter log entry...",
              onSubmit: () => c.addLog(),
            ),
          ),
        ],
      ),
    );
  }
}
