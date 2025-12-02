import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/views/home/widgets/quest_editor.dart';
import 'package:my_life_rpg/views/session/session_binding.dart';
import '../../../models/quest.dart';
import '../../session/session_view.dart';

class MissionCard extends StatelessWidget {
  final Quest quest;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggle;

  const MissionCard({
    super.key,
    required this.quest,
    this.onTap,
    this.onLongPress,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 区分类型
    final isDaemon = quest.type == QuestType.daemon;
    final dueDays = quest.dueDays ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderDim),
      ),
      // 使用 ClipRRect 确保水波纹不溢出圆角
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusMd,
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
                    color: isDaemon
                        ? AppColors.accentSystem.withOpacity(0.1) // 循环任务用青色背景区分
                        : Colors.white.withOpacity(0.02),
                    alignment: Alignment.center,
                    child: isDaemon
                        ? Icon(
                            Icons.refresh,
                            size: AppSpacing.iconMd - 2,
                            color: AppColors.accentSystem,
                          ) // 循环图标
                        : Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
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
                                    color: AppColors.accentMain,
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
                          Text(quest.title, style: AppTextStyles.body),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Time Info
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Text(
                  "${(quest.totalDurationSeconds / 3600).toStringAsFixed(1)}h",
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
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
          Text(
            quest.isAllDayDeadline
                ? DateFormat('MM-dd').format(quest.deadline!)
                : DateFormat('MM-dd HH:mm').format(quest.deadline!),
            style: AppTextStyles.micro.copyWith(color: color, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
