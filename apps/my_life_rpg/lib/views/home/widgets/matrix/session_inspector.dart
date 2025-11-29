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

  const SessionInspector({Key? key, required this.quest, required this.session})
    : super(key: key);

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

    return Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.history, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  "MEMORY FRAGMENT",
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quest Title
            Text(
              quest.title,
              style: AppTextStyles.panelHeader.copyWith(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            if (quest.projectName != null)
              RpgTag(label: quest.projectName!, color: color),

            const SizedBox(height: 20),

            // Time Info Box
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

            const SizedBox(height: 24),

            // Logs Preview (如果有多条)
            if (session.logs.isNotEmpty) ...[
              Text("LOGS DATA:", style: AppTextStyles.micro),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                RpgButton(
                  label: "DELETE RECORD",
                  type: RpgButtonType.danger,
                  icon: Icons.delete_forever,
                  onTap: () {
                    // 二次确认
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
            ),
          ],
        ),
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
