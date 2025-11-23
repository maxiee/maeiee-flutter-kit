import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/game_controller.dart';
import '../../../models/quest.dart';
// import '../../session/session_view.dart'; // 稍后集成

class MissionCard extends StatelessWidget {
  final Quest quest;
  final GameController c = Get.find();

  MissionCard({Key? key, required this.quest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: IntrinsicHeight(
        // 让子元素高度一致
        child: Row(
          children: [
            // 1. Checkbox Area (Finisher)
            InkWell(
              onTap: () => c.toggleQuestCompletion(quest.id),
              child: Container(
                width: 40,
                color: Colors.white.withOpacity(0.02),
                alignment: Alignment.center,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // 分割线
            const VerticalDivider(width: 1, color: Colors.white10),

            // 2. Content Area (Go to Session)
            Expanded(
              child: InkWell(
                onTap: () {
                  // 跳转到 SessionView (驾驶舱)
                  // Get.to(() => SessionView(), arguments: quest);
                  print("Go to Session: ${quest.title}");
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 如果有关联项目，显示 Tag
                      if (quest.projectName != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            quest.projectName!,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      // 任务标题
                      Text(
                        quest.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Time Info
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                "${(quest.totalDurationSeconds / 3600).toStringAsFixed(1)}h",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
