import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/core/theme/app_colors.dart';
import 'package:my_life_rpg/core/theme/app_text_styles.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import '../../../models/quest.dart';
import '../../session/session_view.dart';

class MissionCard extends StatelessWidget {
  final Quest quest;
  final QuestService q = Get.find();

  MissionCard({Key? key, required this.quest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 区分类型
    final isDaemon = quest.type == QuestType.daemon;
    final dueDays = quest.dueDays ?? 0;

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
            // 1. Checkbox / Reset Button
            InkWell(
              onTap: () => q.toggleQuestCompletion(quest.id),
              child: Container(
                width: 40,
                color: isDaemon
                    ? Colors.cyan.withOpacity(0.1) // 循环任务用青色背景区分
                    : Colors.white.withOpacity(0.02),
                alignment: Alignment.center,
                child: isDaemon
                    ? const Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.cyanAccent,
                      ) // 循环图标
                    : Container(
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
                onTap: () async {
                  // 1. 等待 SessionView 关闭，并捕获返回结果 (sessionDuration)
                  final result = await Get.to(
                    () => SessionView(),
                    arguments: quest,
                  );

                  // 2. 如果 result 不为空，说明是通过 "TERMINATE" 按钮正常结束的
                  if (result != null && result is int) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "任务结算",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                              Text(
                                "投入了 ${(result / 60).toStringAsFixed(1)} 分钟",
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1E1E1E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(
                              color: Colors.white12,
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
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
                      Row(
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
                                  color: AppColors.accentMain,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          // Daemon Urgency Tag
                          if (isDaemon && dueDays > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                "OVERDUE +$dueDays",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (quest.deadline != null) ...[
                            Container(
                              margin: const EdgeInsets.only(
                                right: 6,
                                bottom: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: quest.hoursUntilDeadline < 0
                                      ? Colors.red
                                      : quest.hoursUntilDeadline < 24
                                      ? Colors.amber
                                      : Colors.grey,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 8,
                                    color: quest.hoursUntilDeadline < 0
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    quest.isAllDayDeadline
                                        ? DateFormat(
                                            'MM-dd',
                                          ).format(quest.deadline!)
                                        : DateFormat(
                                            'MM-dd HH:mm',
                                          ).format(quest.deadline!),
                                    style: TextStyle(
                                      color: quest.hoursUntilDeadline < 0
                                          ? Colors.red
                                          : Colors.grey,
                                      fontSize: 9,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      // 任务标题
                      Text(quest.title, style: AppTextStyles.body),
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
