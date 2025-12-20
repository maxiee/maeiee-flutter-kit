import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/task_service.dart';
import '../../../models/task.dart';

class MissionCard extends StatefulWidget {
  final Task quest;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggle;

  MissionCard({
    super.key,
    required this.quest,
    this.onTap,
    this.onLongPress,
    this.onToggle,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    with SingleTickerProviderStateMixin {
  final TaskService _qs = Get.find();
  bool isExpanded = false; // [新增] 展开状态

  @override
  Widget build(BuildContext context) {
    // 1. 确定颜色逻辑
    // 默认颜色
    Color accentColor = widget.quest.type == TaskType.routine
        ? AppColors.accentSystem
        : AppColors.accentMain;

    // [新增] 如果有关联项目，优先使用项目颜色
    if (widget.quest.projectId != null) {
      final Project? proj = _qs.projects.firstWhereOrNull(
        (p) => p.id == widget.quest.projectId,
      );
      if (proj != null) {
        accentColor = proj.color;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- A. 主卡片区域 ---
        RpgContainer(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 1. Checkbox (直接触发，无动画)
                Material(
                  child: InkWell(
                    onTap: widget.onToggle,
                    child: Container(
                      width: 40,
                      color: accentColor.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: widget.quest.type == TaskType.routine
                          ? Icon(
                              Icons.refresh,
                              size: AppSpacing.iconMd - 2,
                              color: accentColor,
                            )
                          : Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(color: accentColor),
                                borderRadius: AppSpacing.borderRadiusSm,
                              ),
                            ),
                    ),
                  ),
                ),

                const RpgVerticalDivider(width: 1),

                // 2. 核心内容区
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      onLongPress: widget.onLongPress,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Tags Row
                            Row(
                              children: [
                                if (widget.quest.projectName != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xs,
                                    ),
                                    child: RpgTag(
                                      label: widget.quest.projectName!,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                if (widget.quest.deadline != null) ...[
                                  _buildDeadlineTag(accentColor),
                                ],
                              ],
                            ),

                            // Title
                            RpgText.body(widget.quest.title),

                            // Progress Bar (仅当未展开且有子任务时显示概览)
                            if (widget.quest.checklist.isNotEmpty &&
                                !isExpanded) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: widget.quest.checklistProgress,
                                        backgroundColor: Colors.white10,
                                        color: accentColor,
                                        minHeight: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RpgText.micro(
                                    "${widget.quest.checklist.where((e) => e.isCompleted).length}/${widget.quest.checklist.length}",
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

                // 3. 右侧操作区 (时间 + 展开按钮)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // 如果有子任务，点击这里展开；否则无响应(或只看时间)
                    onTap: widget.quest.checklist.isNotEmpty
                        ? () => setState(() => isExpanded = !isExpanded)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RpgText.caption(
                            "${(widget.quest.totalDurationSeconds / 3600).toStringAsFixed(1)}h",
                            color: Colors.grey,
                          ),
                          // 仅当有子任务时显示箭头
                          if (widget.quest.checklist.isNotEmpty)
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white30,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- B. 展开的子任务面板 ---
        if (isExpanded)
          Container(
            // 缩进设计：体现从属关系
            margin: const EdgeInsets.only(left: 40, right: 4, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.black26, // 深色背景区分层级
              border: Border(
                left: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
                bottom: BorderSide(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
                right: BorderSide(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
            ),
            child: Column(
              children: List.generate(widget.quest.checklist.length, (i) {
                final sub = widget.quest.checklist[i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _toggleSubTask(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // 小 Checkbox
                          Icon(
                            sub.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 16,
                            color: sub.isCompleted
                                ? Colors.grey
                                : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          // 子任务文本
                          Expanded(
                            child: Text(
                              sub.title,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 12,
                                color: sub.isCompleted
                                    ? Colors.grey
                                    : Colors.white,
                                decoration: sub.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildDeadlineTag(Color color) {
    final text = widget.quest.isAllDayDeadline
        ? DateFormat('MM-dd').format(widget.quest.deadline!)
        : DateFormat('MM-dd HH:mm').format(widget.quest.deadline!);

    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: AppSpacing.xs),
      child: RpgText.micro(text, color: Colors.grey),
    );
  }

  // 切换子任务状态
  void _toggleSubTask(int index) {
    final sub = widget.quest.checklist[index];

    // 1. 修改本地状态 (UI即时反馈)
    setState(() {
      sub.isCompleted = !sub.isCompleted;
    });

    // 2. 调用 Service 持久化
    _qs.updateTask(widget.quest.id, checklist: widget.quest.checklist);
  }
}
