import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/task_service.dart';
import '../../../models/task.dart';

class MissionCard extends StatelessWidget {
  final Task quest;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggle;

  final TaskService _qs = Get.find();

  MissionCard({
    super.key,
    required this.quest,
    this.onTap,
    this.onLongPress,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 确定颜色逻辑
    // 默认颜色
    Color accentColor = quest.type == TaskType.routine
        ? AppColors.accentSystem
        : AppColors.accentMain;

    // [新增] 如果有关联项目，优先使用项目颜色
    if (quest.projectId != null) {
      final Project? proj = _qs.projects.firstWhereOrNull(
        (p) => p.id == quest.projectId,
      );
      if (proj != null) {
        accentColor = proj.color;
      }
    }

    // 区分类型
    final isDaemon = quest.type == TaskType.routine;
    final dueDays = quest.dueDays ?? 0;

    return RpgContainer(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        // 让子元素高度一致
        child: Row(
          children: [
            // 1. 左侧 Checkbox 区域 (仅响应点击)
            Material(
              child: InkWell(
                onTap: onToggle,
                child: Container(
                  width: 40,
                  color: accentColor.withOpacity(0.1),
                  alignment: Alignment.center,
                  child: isDaemon
                      ? Icon(
                          Icons.refresh,
                          size: AppSpacing.iconMd - 2,
                          color: accentColor, // [修改] 图标颜色
                        ) // 循环图标
                      : Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(color: accentColor), // [修改] 边框颜色
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                        ),
                ),
              ),
            ),

            // 分割线
            const RpgVerticalDivider(width: 1),

            // 2. Content Area (Go to Session)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  // 长按 -> 编辑
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            // 如果有关联项目，显示 Tag
                            if (quest.projectName != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: RpgTag(
                                  label: quest.projectName!,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            // Daemon Urgency Tag
                            if (isDaemon && dueDays > 0) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: RpgTag(
                                  label: "OVERDUE +$dueDays",
                                  color: AppColors.accentDanger,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (quest.deadline != null) ...[
                              _buildDeadlineTag(),
                            ],
                          ],
                        ),
                        // 任务标题
                        RpgText.body(quest.title),
                        // [新增] 子任务微型进度条
                        if (quest.checklist.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // 进度条
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: quest.checklistProgress,
                                    backgroundColor: Colors.white10,
                                    color: accentColor,
                                    minHeight: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 数字 2/5
                              RpgText.micro(
                                "${quest.checklist.where((e) => e.isCompleted).length}/${quest.checklist.length}",
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Time Info
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: RpgText.caption(
                "${(quest.totalDurationSeconds / 3600).toStringAsFixed(1)}h",
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineTag() {
    final isOverdue = quest.hoursUntilDeadline < 0;
    final isUrgent = quest.hoursUntilDeadline < 24;
    final color = isOverdue
        ? AppColors.accentDanger
        : isUrgent
        ? Colors.amber
        : Colors.grey;
    final text = quest.isAllDayDeadline
        ? DateFormat('MM-dd').format(quest.deadline!)
        : DateFormat('MM-dd HH:mm').format(quest.deadline!);

    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: AppSpacing.iconXs, color: color),
          const SizedBox(width: 2),
          RpgText.micro(text, color: color),
        ],
      ),
    );
  }
}
