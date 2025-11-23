import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/game_controller.dart';
import '../../../models/quest.dart';
import 'routine_card.dart';

/// "系统守护进程监控 (System Daemon Monitor)"。
class RoutinePanel extends StatelessWidget {
  final GameController c = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // 与左侧保持一致的底色
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: const [
                Icon(
                  Icons.settings_system_daydream,
                  color: Colors.cyanAccent,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  "系统守护 (日常)", // 这里的文案用 DAEMONS 比 ROUTINES 更极客
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Obx(() {
              // 1. 筛选出 routine
              final routines = c.quests
                  .where((q) => q.type == QuestType.routine)
                  .toList();

              // 2. 排序逻辑：逾期的(dueDays > 0)排在前面，且逾期越久越靠前
              routines.sort((a, b) {
                final dueA = a.dueDays ?? 0;
                final dueB = b.dueDays ?? 0;
                return dueB.compareTo(dueA); // 降序排列
              });

              if (routines.isEmpty) {
                return const Center(
                  child: Text(
                    "ALL SYSTEMS OPERATIONAL",
                    style: TextStyle(
                      color: Colors.white24,
                      fontFamily: 'Courier',
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: routines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => RoutineCard(quest: routines[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
