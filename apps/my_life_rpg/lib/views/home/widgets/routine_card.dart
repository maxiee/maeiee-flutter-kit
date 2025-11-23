import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../session/session_view.dart'; // 引入 SessionView
import '../../../models/quest.dart';

/// 像系统的“健康监控日志”。
class RoutineCard extends StatelessWidget {
  final Quest quest;
  const RoutineCard({Key? key, required this.quest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dueDays = quest.dueDays ?? 0;
    final isOverdue = dueDays > 0;
    final color = isOverdue ? Colors.redAccent : Colors.greenAccent;

    return InkWell(
      onTap: () async {
        final result = await Get.to(() => SessionView(), arguments: quest);
        if (result != null && result is int) {
          Get.snackbar(
            "守护进程更新",
            "系统维护完毕。投入 ${(result / 60).toStringAsFixed(1)} 分钟",
            backgroundColor: const Color(0xFF1E1E1E),
            colorText: Colors.cyanAccent,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            borderColor: Colors.white12,
            borderWidth: 1,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 4)), // 左边框指示状态
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                quest.title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isOverdue ? "OVERDUE +$dueDays d" : "READY in ${-dueDays} d",
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
