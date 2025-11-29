import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/views/home/widgets/mission_card.dart';
import 'package:my_life_rpg/views/home/widgets/quest_editor.dart';
import '../../../controllers/game_controller.dart';
import '../../../models/quest.dart';
// import 'mission_card.dart'; // 稍后实现

class MissionPanel extends StatelessWidget {
  final GameController c = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    "ACTIVE OPERATIONS",
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Command Cluster (指令组)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Daemon Button (Cyan)
                    IconButton(
                      icon: const Icon(Icons.loop, size: 20),
                      color: Colors.cyanAccent,
                      tooltip: "Initialize Daemon (循环任务)",
                      constraints: const BoxConstraints(), // 紧凑
                      padding: const EdgeInsets.all(8),
                      onPressed: () =>
                          Get.dialog(const QuestEditor(type: QuestType.daemon)),
                    ),

                    const SizedBox(width: 4), // 按钮间距
                    // 2. Mission Button (Orange)
                    IconButton(
                      icon: const Icon(Icons.add_task, size: 20),
                      color: Colors.orangeAccent,
                      tooltip: "Deploy Mission (普通任务)",
                      constraints: const BoxConstraints(), // 紧凑
                      padding: const EdgeInsets.all(8),
                      onPressed: () => Get.dialog(
                        const QuestEditor(type: QuestType.mission),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: Obx(() {
              // 混合筛选逻辑
              final activeTasks = c.quests.where((q) {
                if (q.type == QuestType.mission) {
                  return !q.isCompleted; // 未完成的普通任务
                } else {
                  // 循环任务：显示 逾期的(dueDays>=0)
                  // 或者 你也可以选择始终显示，但用排序区分。
                  // 建议：只显示需要处理的 (dueDays >= -1，比如明天到期的也显示出来预警)
                  final due = q.dueDays ?? 0;
                  return due >= -1;
                }
              }).toList();

              // 混合排序逻辑
              activeTasks.sort((a, b) {
                // 0. 超级优先级：逾期的 Deadline (hoursUntilDeadline < 0)
                if (a.hoursUntilDeadline < 0 && b.hoursUntilDeadline >= 0) {
                  return -1;
                }
                if (b.hoursUntilDeadline < 0 && a.hoursUntilDeadline >= 0) {
                  return 1;
                }

                // 1. 优先级：24小时内到期的 Deadline
                bool aUrgent = a.hoursUntilDeadline < 24;
                bool bUrgent = b.hoursUntilDeadline < 24;
                if (aUrgent && !bUrgent) return -1;
                if (!aUrgent && bUrgent) return 1;

                // 1. 优先级：逾期的循环任务最高
                bool aIsUrgentDaemon = a.type == QuestType.daemon;
                bool bIsUrgentDaemon = b.type == QuestType.daemon;

                if (aIsUrgentDaemon && !bIsUrgentDaemon) return -1;
                if (!aIsUrgentDaemon && bIsUrgentDaemon) return 1;

                // 2. 如果都是 Daemon，逾期越久的越靠前
                if (aIsUrgentDaemon && bIsUrgentDaemon) {
                  return (b.dueDays ?? 0).compareTo(a.dueDays ?? 0);
                }

                // 3. 如果都是 Mission，保持默认顺序 (或按最后活跃时间)
                return 0;
              });

              if (activeTasks.isEmpty) {
                return const Center(
                  child: Text(
                    "NO ACTIVE OPERATIONS",
                    style: TextStyle(
                      color: Colors.white12,
                      fontFamily: 'Courier',
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: activeTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => MissionCard(quest: activeTasks[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
