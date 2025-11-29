import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import '../../../models/project.dart';

class CampaignBar extends StatelessWidget {
  final QuestService q = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // 紧凑高度
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: q.projects.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) => _buildProjectChip(q.projects[i]),
        ),
      ),
    );
  }

  Widget _buildProjectChip(Project p) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            p.title,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 简易进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: p.progress,
              backgroundColor: Colors.black,
              valueColor: const AlwaysStoppedAnimation(Colors.orange),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}
