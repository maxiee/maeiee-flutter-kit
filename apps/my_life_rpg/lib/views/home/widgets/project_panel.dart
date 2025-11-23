import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/game_controller.dart';
import '../../../models/quest.dart';
import 'project_card.dart';

/// RPG 的“技能树”或“任务日志”。
class ProjectPanel extends StatelessWidget {
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
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: const [
                Icon(Icons.code, color: Colors.orangeAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  "ACTIVE QUESTS (PROJECTS)",
                  style: TextStyle(
                    color: Colors.orangeAccent,
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
              final projects = c.quests
                  .where((q) => q.type == QuestType.project)
                  .toList();
              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => ProjectCard(quest: projects[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
