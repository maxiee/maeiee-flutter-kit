import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';

class SessionInspector extends StatelessWidget {
  final Task quest;
  final FocusSession session;

  const SessionInspector({
    super.key,
    required this.quest,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final TaskService qs = Get.find();

    // 计算时间
    final startStr = DateFormat('HH:mm').format(session.startTime);
    final endStr = session.endTime != null
        ? DateFormat('HH:mm').format(session.endTime!)
        : "NOW";
    final durationMin = session.durationSeconds ~/ 60;

    // 颜色
    final color = quest.type == TaskType.routine
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
          RpgContainer(
            style: RpgContainerStyle.panel,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RpgStat(
                  label: "START",
                  value: startStr,
                  compact: true,
                  alignment: CrossAxisAlignment.start,
                ),
                const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                RpgStat(
                  label: "END",
                  value: endStr,
                  compact: true,
                  alignment: CrossAxisAlignment.start,
                ),
                Container(width: 1, height: 24, color: Colors.white10),
                RpgStat(
                  label: "DURATION",
                  value: "${durationMin}m",
                  valueColor: AppColors.accentSafe,
                  compact: true,
                  alignment: CrossAxisAlignment.end,
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
}
