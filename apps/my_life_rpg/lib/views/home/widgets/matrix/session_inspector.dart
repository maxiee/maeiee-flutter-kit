// lib/views/home/widgets/matrix/session_inspector.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/models/quest.dart';
import 'package:my_life_rpg/services/quest_service.dart';

class SessionInspector extends StatelessWidget {
  final Quest quest;
  final QuestSession session;

  const SessionInspector({
    super.key,
    required this.quest,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final QuestService qs = Get.find();

    // 计算时间
    final startStr = DateFormat('HH:mm').format(session.startTime);
    final endStr = session.endTime != null
        ? DateFormat('HH:mm').format(session.endTime!)
        : "NOW";
    final durationMin = session.durationSeconds ~/ 60;

    // 颜色
    final color = quest.type == QuestType.daemon
        ? AppColors.accentSystem
        : AppColors.accentMain;

    return RpgDialog(
      title: "MEMORY FRAGMENT",
      icon: Icons.history,
      accentColor: color,
      onCancel: () => Get.back(), // 显示默认的 CLOSE/CANCEL 按钮
      actions: [
        // 删除按钮
        RpgButton(
          label: "DELETE RECORD",
          type: RpgButtonType.danger,
          icon: Icons.delete_forever,
          onTap: () {
            // 二次确认 (复用 Get.defaultDialog 或以后也改成 RpgDialog，暂时保持 Get 自带的以示区别)
            Get.defaultDialog(
              title: "CONFIRM DELETION",
              titleStyle: AppTextStyles.panelHeader.copyWith(
                color: AppColors.accentDanger,
              ),
              content: const Text(
                "This action will remove the time record and revoke XP.\nAre you sure?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              backgroundColor: AppColors.bgPanel,
              confirmTextColor: Colors.white,
              textConfirm: "DELETE",
              textCancel: "CANCEL",
              buttonColor: AppColors.accentDanger,
              onConfirm: () {
                qs.deleteSession(quest.id, session.id);
                Get.back(); // Close Confirm
                Get.back(); // Close Inspector
                Get.snackbar("Deleted", "Memory fragment removed.");
              },
            );
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 任务标题 & 项目标签
          Text(
            quest.title,
            style: AppTextStyles.panelHeader.copyWith(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          if (quest.projectName != null) ...[
            const SizedBox(height: 4),
            RpgTag(label: quest.projectName!, color: color),
          ],

          AppSpacing.gapV20,

          // 2. 时间信息块 (Time Capsule)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat("START", startStr),
                const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                _buildStat("END", endStr),
                Container(width: 1, height: 24, color: Colors.white10),
                _buildStat(
                  "DURATION",
                  "${durationMin}m",
                  valueColor: Colors.white,
                ),
              ],
            ),
          ),

          // 3. 日志预览 (如果有)
          if (session.logs.isNotEmpty) ...[
            AppSpacing.gapV24,
            const Text("LOGS DATA:", style: AppTextStyles.micro),
            AppSpacing.gapV8,
            Container(
              constraints: const BoxConstraints(maxHeight: 120), // 限制高度
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: session.logs.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "> ${session.logs[i].content}",
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.micro.copyWith(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Courier',
            color: valueColor ?? AppColors.accentSafe,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
