import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/views/home/widgets/project_editor.dart';

class CampaignBar extends StatelessWidget {
  final TaskService q = Get.find();

  CampaignBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // 1. 固定在左侧的添加按钮
          _buildAddButton(),

          const SizedBox(width: 8),

          // 2. 可滚动的项目列表区
          Expanded(
            child: Obx(
              () => ListView.separated(
                scrollDirection: Axis.horizontal,
                // 给右侧留点余地
                padding: const EdgeInsets.only(right: 4),
                itemCount: q.projects.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => _buildProjectBlock(q.projects[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 样式：虚线框或低对比度框，表示“空插槽”
  Widget _buildAddButton() {
    return Tooltip(
      message: "Initialize New Protocol",
      child: InkWell(
        onTap: () => Get.dialog(const ProjectEditor()),
        borderRadius: BorderRadius.circular(4),
        child: const RpgContainer(
          width: 48, // 正方形
          height: 48, // 填满高度
          style: RpgContainerStyle.outline,
          padding: EdgeInsets.zero,
          child: Icon(Icons.add, color: AppColors.accentMain, size: 20),
        ),
      ),
    );
  }

  // 样式：赛博朋克数据块
  Widget _buildProjectBlock(Project p) {
    final MissionController mc = Get.find(); // 获取控制器

    return Obx(() {
      final isSelected =
          mc.activeFilter.value == MissionFilter.project &&
          mc.selectedProjectId.value == p.id;

      final progress = q.getProjectProgress(p.id);
      final percentStr = "${(progress * 100).toInt()}%";

      return InkWell(
        onTap: () => mc.selectProject(p.id), // [修改点]：点击不再是编辑，而是筛选
        onLongPress: () =>
            Get.dialog(ProjectEditor(project: p)), // [修改点]：长按才是编辑
        child: RpgContainer(
          // 使用 AnimatedContainer 做过渡
          width: 130,
          style: RpgContainerStyle.card,
          focused: isSelected,
          overrideColor: p.color, // 将项目颜色传递给容器
          padding: EdgeInsets.zero, //
          child: Stack(
            children: [
              // 1. 进度条作为底部填充 (或者底边框)
              // 这里设计为：底部的一条细线，随着进度变长
              Align(
                alignment: Alignment.bottomLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 3, // 极细的进度条
                    decoration: BoxDecoration(
                      color: p.color, // 颜色移到这里
                      boxShadow: [
                        BoxShadow(
                          color: p.color.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. 内容区域
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 上层：标题
                    RpgText.caption(p.title.toUpperCase(), color: Colors.white),
                    const SizedBox(height: 2),
                    // 下层：百分比数字 (Micro Style)
                    RpgText.micro(
                      "PROG: ${(progress * 100).toInt()}%",
                      color: p.color.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
