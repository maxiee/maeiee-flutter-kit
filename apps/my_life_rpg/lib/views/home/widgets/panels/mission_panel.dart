import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/views/home/widgets/mission_card.dart';
import 'package:my_life_rpg/views/home/widgets/quest_editor.dart';
import '../../../../models/quest.dart';

class MissionPanel extends StatelessWidget {
  final QuestService q = Get.find();

  MissionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RpgContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          RpgPanelHeader(
            title: "ACTIVE OPERATIONS",
            actions: [
              // 1. Daemon Button (Cyan)
              RpgIconButton(
                icon: Icons.loop,
                color: AppColors.accentSystem,
                tooltip: "Initialize Daemon (循环任务)",
                onTap: () =>
                    Get.dialog(const QuestEditor(type: QuestType.daemon)),
              ),
              AppSpacing.gapH4,
              // 2. Mission Button (Orange)
              RpgIconButton(
                icon: Icons.add_task,
                color: AppColors.accentMain,
                tooltip: "Deploy Mission (普通任务)",
                onTap: () =>
                    Get.dialog(const QuestEditor(type: QuestType.mission)),
              ),
            ],
          ),
          // List
          Expanded(
            child: Obx(() {
              // 混合筛选逻辑
              final activeTasks = q.quests.where((q) {
                if (q.type == QuestType.mission) {
                  return !q.isCompleted; // 未完成的普通任务
                } else {
                  final due = q.dueDays ?? 0;
                  return due >= -1;
                }
              }).toList();

              // 混合排序逻辑
              activeTasks.sort((a, b) {
                // 0. 超级优先级：逾期的 Deadline
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

                // 3. 如果都是 Mission，保持默认顺序
                return 0;
              });

              if (activeTasks.isEmpty) {
                return const RpgEmptyState(message: "NO ACTIVE OPERATIONS");
              }

              return ListView.separated(
                padding: AppSpacing.paddingSm,
                itemCount: activeTasks.length,
                separatorBuilder: (_, __) => AppSpacing.gapV8,
                itemBuilder: (ctx, i) => MissionCard(quest: activeTasks[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
