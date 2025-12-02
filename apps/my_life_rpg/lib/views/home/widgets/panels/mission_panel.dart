import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/views/home/widgets/mission_card.dart';
import 'package:my_life_rpg/views/home/widgets/quest_editor.dart';
import 'package:my_life_rpg/views/session/session_binding.dart';
import 'package:my_life_rpg/views/session/session_view.dart';
import '../../../../models/quest.dart';

class MissionPanel extends StatelessWidget {
  final QuestService q = Get.find();
  final MissionController mc = Get.find();

  MissionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RpgContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enhanced Header
          _buildHeader(),
          const RpgDivider(),
          // 2. Filtered List
          Expanded(
            child: Obx(() {
              final tasks = mc.filteredQuests; // 使用 Controller 的过滤结果

              if (tasks.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: AppSpacing.paddingSm,
                itemCount: tasks.length,
                separatorBuilder: (_, __) => AppSpacing.gapV8,
                itemBuilder: (ctx, i) {
                  final quest = tasks[i];
                  // [修改点]: 在这里注入业务逻辑
                  return MissionCard(
                    quest: quest,
                    onToggle: () => q.toggleQuestCompletion(quest.id),
                    onLongPress: () => Get.dialog(QuestEditor(quest: quest)),
                    onTap: () => _handleCardTap(context, quest),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _handleCardTap(BuildContext context, Quest quest) async {
    final result = await Get.to(
      () => SessionView(),
      arguments: quest,
      binding: SessionBinding(),
    );

    // 反馈逻辑
    if (result != null && result is int && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("投入了 ${(result / 60).toStringAsFixed(1)} 分钟"),
          backgroundColor: AppColors.bgPanel,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 左侧：过滤器 Tab
          _buildFilterTab("ALL", MissionFilter.all),
          AppSpacing.gapH8,
          _buildFilterTab(
            "URGENT",
            MissionFilter.priority,
            icon: Icons.warning_amber,
            color: AppColors.accentDanger,
          ),
          AppSpacing.gapH8,
          _buildFilterTab(
            "DAEMON",
            MissionFilter.daemon,
            icon: Icons.loop,
            color: AppColors.accentSystem,
          ),

          // 如果当前选了项目，显示项目标签
          Obx(() {
            if (mc.activeFilter.value == MissionFilter.project) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: RpgTag(
                  label: "PROJECT FILTER ACTIVE",
                  color: AppColors.accentMain,
                  icon: Icons.filter_alt,
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const Spacer(),

          // 右侧：添加按钮 (保持原样)
          RpgIconButton(
            icon: Icons.loop,
            color: AppColors.accentSystem,
            tooltip: "Initialize Daemon",
            onTap: () => Get.dialog(const QuestEditor(type: QuestType.daemon)),
          ),
          RpgIconButton(
            icon: Icons.add_task,
            color: AppColors.accentMain,
            tooltip: "Deploy Mission",
            onTap: () => Get.dialog(const QuestEditor(type: QuestType.mission)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    String label,
    MissionFilter filter, {
    IconData? icon,
    Color? color,
  }) {
    return Obx(() {
      final isActive = mc.activeFilter.value == filter;
      final displayColor = isActive ? (color ?? Colors.white) : Colors.grey;

      return InkWell(
        onTap: () => mc.setFilter(filter),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? displayColor.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isActive ? displayColor : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: displayColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.micro.copyWith(
                  color: displayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.white10),
          AppSpacing.gapV16,
          Text("NO OPERATIONS FOUND", style: AppTextStyles.caption),
          Text(
            "ADJUST FILTERS OR DEPLOY NEW",
            style: AppTextStyles.micro.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
