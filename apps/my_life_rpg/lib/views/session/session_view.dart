import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import '../../controllers/session_controller.dart';
import '../../models/task.dart';

class SessionView extends StatelessWidget {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController c = Get.find();

    return Scaffold(
      backgroundColor: AppColors.bgDarkest, // 比首页更深一点，更沉浸
      body: SafeArea(
        child: Column(
          children: [
            // 1. 顶部状态栏 (Header)
            _buildHeader(c),

            // 2. 呼吸计时器 (Pulse Timer) -> 改为支持点击暂停
            // [修改] 优化后的计时器区域
            GestureDetector(
              onTap: c.togglePause,
              child: Container(
                // 固定高度容器，避免布局跳动
                height: 180,
                width: double.infinity,
                // 这里作为 Stack 的容器
                child: Stack(
                  children: [
                    // Layer 1: 动画背景 (60 FPS)
                    Positioned.fill(child: _buildAnimatedBackground(c)),

                    // Layer 2: 数据内容 (1 FPS / Event driven)
                    Positioned.fill(child: _buildTimerContent(c)),
                  ],
                ),
              ),
            ),

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

  Widget _buildAnimatedBackground(SessionController c) {
    return AnimatedBuilder(
      animation: c.pulseAnimation,
      builder: (ctx, child) {
        // 为了获取当前颜色状态，这里不得不读一次 Obx 变量，但我们可以优化
        // 实际上 isPaused 改变频率极低。
        // 我们可以只让 AnimatedBuilder 处理 opacity。
        // 背景色变化放到 Obx 里？
        // 不，背景色和动画状态强相关。
        // 这种混合场景，最优化方案是：
        // 让 AnimatedBuilder 只负责传值给 Container 的 opacity/shadow

        return Obx(() {
          final isPaused = c.isPaused.value;
          // 如果暂停，停止呼吸（虽然 controller 停了，但 value 可能停在中间）
          // 这里的逻辑：暂停变红，非暂停呼吸。

          final opacity = isPaused ? 1.0 : c.pulseAnimation.value;
          final baseColor = isPaused
              ? const Color(0xFF2A0000)
              : const Color(0xFF151515);

          return Container(
            color: baseColor,
            // 我们也可以在这里画一些动态的网格或扫描线，现在先保持简单
          );
        });
      },
    );
  }

  Widget _buildTimerContent(SessionController c) {
    return Obx(() {
      final isPaused = c.isPaused.value;
      // 颜色逻辑也放在这里，因为它不需要 60fps 变化，只有 isPaused 变了才变
      // 只有 text shadow 需要呼吸？
      // 原代码：HeroNumber 的 color 和 shadow 都在呼吸。
      // 如果要让文字呼吸，Obx 还是得套在 AnimatedBuilder 里，或者文字单独套 AnimatedBuilder。

      final label = isPaused ? "SYSTEM PAUSED" : "SESSION IN PROGRESS";
      final stateColor = isPaused
          ? AppColors.accentDanger
          : AppColors.accentMain;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 时间文字：单独套一个 AnimatedBuilder 来做呼吸效果，避免重排版整个 Column
          AnimatedBuilder(
            animation: c.pulseAnimation,
            builder: (_, __) {
              final opacity = isPaused ? 1.0 : c.pulseAnimation.value;
              return Text(
                c.formatDuration(c.effectiveSeconds.value),
                style: AppTextStyles.heroNumber.copyWith(
                  color: stateColor.withOpacity(opacity),
                  shadows: [
                    BoxShadow(
                      color: stateColor.withOpacity(0.3 * opacity),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),

          AppSpacing.gapV4,

          // 状态标签
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPaused)
                const Icon(
                  Icons.pause,
                  color: AppColors.accentDanger,
                  size: 14,
                ),
              if (isPaused) AppSpacing.gapH8,
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isPaused ? AppColors.accentDanger : AppColors.textDim,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // 提示语
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              isPaused ? "TAP TO RESUME" : "TAP TO PAUSE",
              style: AppTextStyles.micro.copyWith(
                color: isPaused ? Colors.white30 : Colors.black, // 黑字=隐藏式提示
              ),
            ),
          ),
        ],
      );
    });
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

  Widget _buildLogRow(SessionController c, TaskLog log) {
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
