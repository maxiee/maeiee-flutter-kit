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
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ACTIVE MISSIONS (执行清单)",
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_box_outlined,
                    color: Colors.orangeAccent,
                  ),
                  onPressed: () =>
                      Get.dialog(const QuestEditor(type: QuestType.mission)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // 紧凑布局
                  tooltip: "Deploy Mission",
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: Obx(() {
              // 筛选出 Mission 类型，且未完成的任务
              final missions = c.quests
                  .where((q) => q.type == QuestType.mission && !q.isCompleted)
                  .toList();

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: missions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => MissionCard(quest: missions[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
