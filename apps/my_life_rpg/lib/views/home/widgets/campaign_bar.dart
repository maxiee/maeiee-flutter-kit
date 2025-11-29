import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/views/home/widgets/project_editor.dart';

class CampaignBar extends StatelessWidget {
  final QuestService q = Get.find();

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
        child: Container(
          width: 48, // 正方形
          height: 48, // 填满高度
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.3), //稍微暗一点，区分内容
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.add, color: AppColors.accentMain, size: 20),
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
        child: AnimatedContainer(
          // 使用 AnimatedContainer 做过渡
          duration: const Duration(milliseconds: 200),
          width: 130,
          decoration: BoxDecoration(
            color: isSelected
                ? p.color.withOpacity(0.15)
                : AppColors.bgCard, // 选中背景变亮
            border: Border(
              left: BorderSide(
                color: p.color,
                width: isSelected ? 6 : 3, // 选中左侧条变宽
              ),
              // 选中时，边框发光
              top: BorderSide(
                color: isSelected
                    ? p.color.withOpacity(0.5)
                    : Colors.white.withOpacity(0.05),
              ),
              right: BorderSide(
                color: isSelected
                    ? p.color.withOpacity(0.5)
                    : Colors.white.withOpacity(0.05),
              ),
              bottom: BorderSide(
                color: isSelected
                    ? p.color.withOpacity(0.5)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: p.color.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
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
                    Text(
                      p.title.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11, // 字体调小，更精致
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // 下层：百分比数字 (Micro Style)
                    Text(
                      "PROG: $percentStr",
                      style: AppTextStyles.micro.copyWith(
                        color: p.color.withOpacity(0.8),
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
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
