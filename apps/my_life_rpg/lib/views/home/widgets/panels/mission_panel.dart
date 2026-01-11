import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/views/home/widgets/mission_card.dart';
import 'package:my_life_rpg/views/home/widgets/quest_editor.dart';
import 'package:my_life_rpg/views/session/session_binding.dart';
import 'package:my_life_rpg/views/session/session_view.dart';
import '../../../../models/task.dart';

class MissionPanel extends StatelessWidget {
  final TaskService q = Get.find();
  final MissionController mc = Get.find();

  MissionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return RpgContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enhanced Header (Breadcrumb Style)
          _buildHeader(),

          const RpgDivider(),

          // 2. Filtered List
          Expanded(
            child: Obx(() {
              final tasks = mc.filteredQuests; // 逻辑已在 Phase 3 更新

              if (tasks.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: AppSpacing.paddingSm,
                itemCount: tasks.length,
                separatorBuilder: (_, _) => AppSpacing.gapV8,
                itemBuilder: (ctx, i) {
                  final quest = tasks[i];
                  return MissionCard(
                    quest: quest,
                    onToggle: () => q.toggleTaskCompletion(quest.id),
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

  void _handleCardTap(BuildContext context, Task quest) async {
    final result = await Get.to(
      () => SessionView(),
      arguments: quest,
      binding: SessionBinding(),
    );

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

  // [重构] 头部不再显示 Filter Chips，而是显示当前上下文标题
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 48,
      child: Row(
        children: [
          // 左侧：上下文标题 (Context Title)
          Expanded(child: Obx(() => _buildContextTitle())),

          // 右侧：添加按钮 (保持不变)
          RpgIconButton(
            icon: Icons.loop,
            color: AppColors.accentSystem,
            tooltip: "新建习惯",
            onTap: () => Get.dialog(const QuestEditor(type: TaskType.routine)),
          ),
          RpgIconButton(
            icon: Icons.add_task,
            color: AppColors.accentMain,
            tooltip: "新建待办",
            onTap: () => Get.dialog(const QuestEditor(type: TaskType.todo)),
          ),
        ],
      ),
    );
  }

  // 根据 Controller 状态显示不同的标题
  Widget _buildContextTitle() {
    // 1. 全局模式 (Global Mode)
    if (mc.viewMode.value == ViewMode.global) {
      String title = "UNKNOWN";
      IconData icon = Icons.circle;
      Color color = Colors.grey;

      switch (mc.globalFilterType.value) {
        case 'inbox':
          title = "INBOX / STANDALONE";
          icon = Icons.inbox;
          color = Colors.white;
          break;
        case 'urgent':
          title = "URGENT PROTOCOLS";
          icon = Icons.warning_amber;
          color = AppColors.accentDanger;
          break;
        case 'daemon':
          title = "BACKGROUND DAEMONS";
          icon = Icons.loop;
          color = AppColors.accentSystem;
          break;
      }
      return Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      );
    }
    // 2. 层级模式 (Hierarchy Mode)
    else {
      final dir = mc.activeDirection;
      final pId = mc.selectedProjectId.value;

      // Case A: 选中了项目
      if (pId != null) {
        // 查找项目名称 (这里直接从 Service 找有点低效，但为了简单先这样做，或者在 Controller 里加 getter)
        final project = q.projects.firstWhereOrNull((p) => p.id == pId);
        return Row(
          children: [
            if (dir != null) ...[
              Text(
                dir.title,
                style: AppTextStyles.micro.copyWith(color: Colors.grey),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
            Icon(Icons.folder, color: project?.color ?? Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                project?.title ?? "UNKNOWN PROJECT",
                style: AppTextStyles.caption.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }
      // Case B: 只选中方向
      else if (dir != null) {
        return Row(
          children: [
            Icon(dir.icon, color: dir.color, size: 18),
            const SizedBox(width: 8),
            Text(
              "${dir.title} (ALL)",
              style: AppTextStyles.caption.copyWith(color: dir.color),
            ),
          ],
        );
      }
      // Case C: 初始状态
      else {
        return const Text("DASHBOARD", style: AppTextStyles.caption);
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.white10),
          AppSpacing.gapV16,
          Text("SECTOR EMPTY", style: AppTextStyles.caption),
          Text(
            "No active missions in this sector.",
            style: AppTextStyles.micro.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
