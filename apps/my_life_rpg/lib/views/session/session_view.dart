import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/app_colors.dart';
import 'package:my_life_rpg/core/widgets/rpg_container.dart';
import '../../controllers/session_controller.dart';
import '../../models/quest.dart';

class SessionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.put(SessionController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // 比首页更深一点，更沉浸
      body: SafeArea(
        child: Column(
          children: [
            // 1. 顶部状态栏 (Header)
            _buildHeader(c),

            // 2. 呼吸计时器 (Pulse Timer)
            _buildPulseTimer(c),

            const Divider(height: 1, color: Colors.white10),

            // 3. 战术日志流 (The Stream)
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: c.scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: c.displayLogs.length, // <--- 只有这里改了变量名
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: Colors.white38, size: 18),
              const SizedBox(width: 8),
              Text(
                c.quest.title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // 退出按钮
          InkWell(
            onTap: c.endSession,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "TERMINATE",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
            ),
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          color: Color(0xFF151515),
          child: Column(
            children: [
              Obx(
                () => Text(
                  c.formatDuration(c.durationSeconds.value),
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentMain.withOpacity(
                      c.pulseAnimation.value,
                    ), // 呼吸效果
                    letterSpacing: 6,
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
              const SizedBox(height: 4),
              Text(
                "SESSION IN PROGRESS",
                style: TextStyle(
                  color: Colors.white12,
                  fontSize: 10,
                  fontFamily: 'Courier',
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
        typeColor = Colors.redAccent;
        typeIcon = Icons.bug_report;
        break;
      case LogType.idea:
        typeColor = Colors.cyanAccent;
        typeIcon = Icons.lightbulb;
        break;
      case LogType.rest:
        typeColor = Colors.greenAccent;
        typeIcon = Icons.coffee;
        break;
      default:
        typeColor = Colors.white54;
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
            style: TextStyle(
              color: Colors.white24,
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Icon(typeIcon, color: typeColor, size: 14),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Text(
              log.content,
              style: TextStyle(
                color: typeColor == Colors.white54 ? Colors.white70 : typeColor,
                fontFamily: 'Courier',
                fontSize: 14,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildMacroChip(c, "🐛 BUG", LogType.bug, "[BUG]"),
                _buildMacroChip(c, "🚩 节点", LogType.milestone, "[节点]"),
                _buildMacroChip(c, "💡 灵感", LogType.idea, "[灵感]"),
                _buildMacroChip(c, "☕ 休息", LogType.rest, ""), // 直接发送
                _buildMacroChip(c, "📝 笔记", LogType.normal, ""),
              ],
            ),
          ),

          // 2. Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                const Text(
                  ">",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: c.textController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter log entry...",
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        fontFamily: 'Courier',
                      ),
                    ),
                    cursorColor: Colors.greenAccent,
                    onSubmitted: (_) => c.addLog(),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.subdirectory_arrow_left,
                    color: Colors.white38,
                  ),
                  onPressed: () => c.addLog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(
    SessionController c,
    String label,
    LogType type,
    String prefix,
  ) {
    Color color;
    switch (type) {
      case LogType.bug:
        color = Colors.redAccent;
        break;
      case LogType.milestone:
        color = Colors.amber;
        break;
      case LogType.idea:
        color = Colors.cyan;
        break;
      case LogType.rest:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => c.triggerMacro(label, type, prefix),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
