import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/views/home/widgets/project_editor.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class ProjectSidebar extends StatelessWidget {
  final MissionController mc = Get.find();
  final TaskService qs = Get.find();

  ProjectSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 只有在层级模式且选中了方向时才显示此栏
      if (mc.viewMode.value != ViewMode.hierarchy ||
          mc.selectedDirectionId.value == null) {
        return const SizedBox.shrink(); // 收起
      }

      final projects = mc.visibleProjects;
      final currentDir = mc.activeDirection;

      return Container(
        width: 160, // 固定宽度二级菜单
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: const Border(right: BorderSide(color: AppColors.borderDim)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Direction Title
            Container(
              padding: const EdgeInsets.all(12),
              color: currentDir?.color.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SECTOR",
                    style: AppTextStyles.micro.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentDir?.title ?? "UNKNOWN",
                    style: AppTextStyles.caption.copyWith(
                      color: currentDir?.color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const RpgDivider(height: 1),

            // Project List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: projects.length + 1, // +1 for Add Button
                itemBuilder: (ctx, i) {
                  if (i == projects.length) {
                    return _buildAddButton(currentDir?.id);
                  }
                  return _buildProjectItem(projects[i]);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProjectItem(Project p) {
    return Obx(() {
      final isSelected = mc.selectedProjectId.value == p.id;
      final progress = qs.getProjectProgress(p.id);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: InkWell(
          onTap: () => mc.selectProject(p.id),
          onLongPress: () => Get.dialog(ProjectEditor(project: p)),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? p.color.withOpacity(0.1) : Colors.transparent,
              border: Border.all(color: isSelected ? p.color : Colors.white10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Tiny Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: Colors.black,
                    color: p.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAddButton(String? dirId) {
    return InkWell(
      // 打开编辑器时，应该自动预填当前 Direction。但 ProjectEditor 暂时还没改支持 directionId
      // 下一步优化时处理，目前先留入口
      onTap: () => Get.dialog(const ProjectEditor()),
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add, color: Colors.grey, size: 16),
      ),
    );
  }
}
