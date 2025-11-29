import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
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
          itemCount: q.projects.length,
          separatorBuilder: (_, __) => AppSpacing.gapH12,
          itemBuilder: (ctx, i) => _buildProjectChip(q.projects[i]),
        ),
      ),
    );
  }

  Widget _buildProjectChip(Project p) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.accentMain.withOpacity(0.3)),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            p.title,
            style: AppTextStyles.body.copyWith(
              color: AppColors.accentMain,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          AppSpacing.gapV4,
          // 简易进度条
          RpgProgress(value: p.progress, color: AppColors.accentMain),
        ],
      ),
    );
  }
}
