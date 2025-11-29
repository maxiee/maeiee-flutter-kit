import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/views/home/widgets/project_editor.dart';
import '../../../models/project.dart';

class CampaignBar extends StatelessWidget {
  final QuestService q = Get.find();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.campaignBarHeight,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: q.projects.length + 1,
          separatorBuilder: (_, __) => AppSpacing.gapH12,
          itemBuilder: (ctx, i) {
            if (i == q.projects.length) {
              return _buildAddButton();
            }
            return _buildProjectChip(q.projects[i]);
          },
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: () => Get.dialog(const ProjectEditor()),
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color: AppColors.bgCard.withOpacity(0.5),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: AppColors.borderDim,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(Icons.add, color: AppColors.textDim),
      ),
    );
  }

  Widget _buildProjectChip(Project p) {
    // [修改点]：点击编辑，使用 p.color
    return InkWell(
      onTap: () => Get.dialog(ProjectEditor(project: p)),
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border.all(color: p.color.withOpacity(0.3)), // 使用动态颜色
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              p.title,
              style: AppTextStyles.body.copyWith(
                color: p.color, // 使用动态颜色
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.gapV4,
            // 进度条颜色也跟随
            RpgProgress(value: q.getProjectProgress(p.id), color: p.color),
          ],
        ),
      ),
    );
  }
}
