import 'package:flutter/material.dart';
import 'package:rpg_cyber_ui/theme/app_colors.dart';
import '../../../models/task.dart';

class ProjectCard extends StatelessWidget {
  final Task quest;
  const ProjectCard({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    // 模拟等级：每10小时升一级
    final level = (quest.totalDurationSeconds / 3600).floor() ~/ 10 + 1;
    final progress = ((quest.totalDurationSeconds / 3600) % 10) / 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // 左侧：等级徽章
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentMain),
            ),
            child: Text(
              "Lv$level",
              style: const TextStyle(
                color: AppColors.accentMain,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 中间：信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          // 右侧：累计时间
          const SizedBox(width: 12),
          Text(
            "${(quest.totalDurationSeconds / 3600).toStringAsFixed(1)}h",
            style: const TextStyle(
              color: Colors.grey,
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
